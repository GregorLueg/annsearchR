//! One opaque index type for every algorithm and float width.
//!
//! R only ever sees `ExternalPtr<AnnIndex>`. Each variant holds a [`Prec`], so
//! the per-algorithm functions match the variant once and then expand the same
//! tokens for `f32` and `f64`. Concrete expansion, not generics, is what
//! discharges bounds such as `HnswState` that the crate only implements for the
//! concrete float types.
//!
//! Shared plumbing (shape, precision, save, load) is generated from the single
//! list in [`ann_indices!`], so a new algorithm is one line there plus its own
//! module.

use ann_search_rs::cpu::annoy::AnnoyIndex;
use ann_search_rs::cpu::exhaustive::ExhaustiveIndex;
use ann_search_rs::cpu::hnsw::HnswIndex;
use ann_search_rs::prelude::AnnSearchErrors;
use ann_search_rs::serialise::IndexIo;
use ann_search_rs::{load_index, save_index};
use extendr_api::prelude::*;
use extendr_api::{Error, Result};

use crate::convert::r_err;

///////////
// Types //
///////////

/// An index tagged with the float type it was built over.
pub enum Prec<A, B> {
    /// Built over `f32` samples.
    F32(A),
    /// Built over `f64` samples.
    F64(B),
}

/// Load a bundle, sniffing the float width.
///
/// The header records the width and is checked before anything is decoded, so
/// a failed `f32` attempt costs one open and a header read.
///
/// ### Params
///
/// * `dir` - Directory holding `index.bin`.
///
/// ### Returns
///
/// The index at whichever width was saved, or the first header, IO or decode
/// error. A bundle from a different algorithm fails the kind check.
fn load_prec<A: IndexIo, B: IndexIo>(dir: &str) -> std::result::Result<Prec<A, B>, AnnSearchErrors> {
    match load_index::<A>(dir) {
        Ok(i) => Ok(Prec::F32(i)),
        Err(AnnSearchErrors::FloatWidthMismatch { .. }) => Ok(Prec::F64(load_index::<B>(dir)?)),
        Err(e) => Err(e),
    }
}

/// Generate [`AnnIndex`] and its shared accessors from one list.
///
/// ### Params
///
/// * `$variant` - Enum variant name.
/// * `$index` - The crate's index type, generic over its float.
/// * `$name` - Algorithm name as the R side spells it.
macro_rules! ann_indices {
    ($($variant:ident => $index:ident, $name:literal;)*) => {
        /// Every index the package can hold, at either float width.
        pub enum AnnIndex {
            $(
                #[doc = concat!("A `", stringify!($index), "`.")]
                $variant(Prec<$index<f32>, $index<f64>>),
            )*
        }

        impl AnnIndex {
            /// Algorithm name.
            ///
            /// ### Returns
            ///
            /// The name the R side uses for this index.
            pub fn algo(&self) -> &'static str {
                match self {
                    $(AnnIndex::$variant(_) => $name,)*
                }
            }

            /// Float width the index was built with.
            ///
            /// ### Returns
            ///
            /// `"float"` or `"double"`.
            pub fn precision(&self) -> &'static str {
                match self {
                    $(
                        AnnIndex::$variant(Prec::F32(_)) => "float",
                        AnnIndex::$variant(Prec::F64(_)) => "double",
                    )*
                }
            }

            /// Shape of the indexed data.
            ///
            /// ### Returns
            ///
            /// `(n_samples, n_features)`.
            pub fn shape(&self) -> (usize, usize) {
                match self {
                    $(
                        AnnIndex::$variant(Prec::F32(i)) => (i.n, i.dim),
                        AnnIndex::$variant(Prec::F64(i)) => (i.n, i.dim),
                    )*
                }
            }

            /// Write the index bundle to disk.
            ///
            /// ### Params
            ///
            /// * `dir` - Target directory, created if missing.
            ///
            /// ### Returns
            ///
            /// Nothing, or the first IO or encoding error.
            pub fn save(&self, dir: &str) -> std::result::Result<(), AnnSearchErrors> {
                match self {
                    $(
                        AnnIndex::$variant(Prec::F32(i)) => save_index(i, dir),
                        AnnIndex::$variant(Prec::F64(i)) => save_index(i, dir),
                    )*
                }
            }

            /// Read a bundle written by [`AnnIndex::save`].
            ///
            /// ### Params
            ///
            /// * `algo` - Algorithm name, as returned by [`AnnIndex::algo`].
            /// * `dir` - Directory holding the bundle.
            ///
            /// ### Returns
            ///
            /// The index, or an error for an unknown algorithm or a bad bundle.
            pub fn load(algo: &str, dir: &str) -> Result<Self> {
                match algo {
                    $(
                        $name => Ok(AnnIndex::$variant(
                            load_prec::<$index<f32>, $index<f64>>(dir).map_err(r_err)?,
                        )),
                    )*
                    _ => Err(Error::Other(format!("unknown index type '{algo}'"))),
                }
            }
        }
    };
}

ann_indices! {
    Exhaustive => ExhaustiveIndex, "exhaustive";
    Annoy => AnnoyIndex, "annoy";
    Hnsw => HnswIndex, "hnsw";
}

/// Error for a pointer that holds a different algorithm than expected.
///
/// ### Params
///
/// * `want` - Algorithm the caller expected.
/// * `got` - The index actually behind the pointer.
///
/// ### Returns
///
/// An extendr error naming both.
pub fn wrong_kind(want: &str, got: &AnnIndex) -> Error {
    Error::Other(format!(
        "expected a '{want}' index, got '{}'",
        got.algo()
    ))
}

////////////
// Macros //
////////////

/// Build an index at the requested precision and wrap it for R.
///
/// `$body` is expanded once per float width with `$mat` bound to the
/// row-major `(Vec<T>, n, dim)` copy of `$data`. It must evaluate to
/// `Result<Index<T>, AnnSearchErrors>`; infallible builders wrap in `Ok`.
macro_rules! build_prec {
    ($data:expr, $precision:expr, $variant:ident, |$mat:ident| $body:expr) => {{
        let inner = match $precision {
            "double" => {
                let $mat = crate::convert::r_to_flat::<f64>(&$data);
                crate::handle::Prec::F64(
                    crate::pool::run(move || $body).map_err(crate::convert::r_err)?,
                )
            }
            _ => {
                let $mat = crate::convert::r_to_flat::<f32>(&$data);
                crate::handle::Prec::F32(
                    crate::pool::run(move || $body).map_err(crate::convert::r_err)?,
                )
            }
        };
        Ok(::extendr_api::prelude::ExternalPtr::new(
            crate::handle::AnnIndex::$variant(inner),
        ))
    }};
}

/// Query an index against new data and pack the result for R.
///
/// `$body` is expanded once per float width with `$idx` bound to the index and
/// `$q` to the row-major copy of `$data` at the index's own width.
macro_rules! query_prec {
    ($ptr:expr, $variant:ident, $name:literal, $data:expr, $k:expr, $sqrt:expr,
     |$idx:ident, $q:ident| $body:expr) => {{
        let crate::handle::AnnIndex::$variant(p) = &*$ptr else {
            return Err(crate::handle::wrong_kind($name, &$ptr));
        };
        match p {
            crate::handle::Prec::F32($idx) => {
                let $q = crate::convert::r_to_flat::<f32>(&$data);
                let (ids, d) = crate::pool::run(move || $body).map_err(crate::convert::r_err)?;
                Ok(crate::convert::pack_knn(ids, d, $k, $sqrt))
            }
            crate::handle::Prec::F64($idx) => {
                let $q = crate::convert::r_to_flat::<f64>(&$data);
                let (ids, d) = crate::pool::run(move || $body).map_err(crate::convert::r_err)?;
                Ok(crate::convert::pack_knn(ids, d, $k, $sqrt))
            }
        }
    }};
}

/// Self-query an index (kNN graph over the indexed data) and pack for R.
///
/// `$body` is expanded once per float width with `$idx` bound to the index.
macro_rules! self_prec {
    ($ptr:expr, $variant:ident, $name:literal, $k:expr, $sqrt:expr, |$idx:ident| $body:expr) => {{
        let crate::handle::AnnIndex::$variant(p) = &*$ptr else {
            return Err(crate::handle::wrong_kind($name, &$ptr));
        };
        match p {
            crate::handle::Prec::F32($idx) => {
                let (ids, d) = crate::pool::run(move || $body).map_err(crate::convert::r_err)?;
                Ok(crate::convert::pack_knn(ids, d, $k, $sqrt))
            }
            crate::handle::Prec::F64($idx) => {
                let (ids, d) = crate::pool::run(move || $body).map_err(crate::convert::r_err)?;
                Ok(crate::convert::pack_knn(ids, d, $k, $sqrt))
            }
        }
    }};
}

pub(crate) use {build_prec, query_prec, self_prec};

///////
// R //
///////

/// Describe an index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Reads the algorithm, precision and shape off an index pointer.
///
/// @param ptr External pointer to an index.
///
/// @returns A list with:
/// \itemize{
///   \item algo - Algorithm name.
///   \item precision - `"float"` or `"double"`.
///   \item n - Number of indexed samples.
///   \item dim - Number of features.
/// }
///
/// @keywords internal
#[extendr]
fn rs_ann_info(ptr: ExternalPtr<AnnIndex>) -> List {
    let (n, dim) = ptr.shape();
    list!(
        algo = ptr.algo(),
        precision = ptr.precision(),
        n = n as i32,
        dim = dim as i32
    )
}

/// Save an index to a directory
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Writes `index.bin` into `dir`. Use the `$save()` method instead.
///
/// @param ptr External pointer to an index.
/// @param dir String. Target directory, created if missing.
///
/// @returns Invisible `NULL`.
///
/// @keywords internal
#[extendr]
fn rs_ann_save(ptr: ExternalPtr<AnnIndex>, dir: &str) -> Result<()> {
    ptr.save(dir).map_err(r_err)
}

/// Load an index from a directory
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Reads a bundle written by [rs_ann_save()]. Use [load_ann_index()] instead.
///
/// @param dir String. Directory holding `index.bin`.
/// @param algo String. Algorithm that wrote the bundle.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
fn rs_ann_load(dir: &str, algo: &str) -> Result<ExternalPtr<AnnIndex>> {
    Ok(ExternalPtr::new(AnnIndex::load(algo, dir)?))
}

extendr_module! {
    mod handle;
    fn rs_ann_info;
    fn rs_ann_save;
    fn rs_ann_load;
}
