//! Moving matrices across the R boundary.
//!
//! R hands over column-major `f64`; the crate wants row-major `T`. Results come
//! back ragged (`Vec<Vec<_>>`, rows can be short) and leave as dense
//! column-major R matrices with 1-based indices.

use ann_search_rs::prelude::AnnSearchErrors;
use extendr_api::prelude::*;
use extendr_api::Error;
use num_traits::{AsPrimitive, Float};
use rayon::prelude::*;

///////////
// Input //
///////////

/// Transpose and cast an R matrix into the crate's row-major layout.
///
/// Parallel over output rows. Reads are strided by `n`, writes are contiguous.
///
/// ### Params
///
/// * `mat` - R matrix of shape samples x features, column-major.
///
/// ### Returns
///
/// `(data, n, dim)` with sample `i` at `data[i * dim..(i + 1) * dim]`. This is
/// the crate's `FlattenData<T>`, which it takes without a further copy.
pub fn r_to_flat<T>(mat: &RMatrix<f64>) -> (Vec<T>, usize, usize)
where
    T: Float + Send + Sync + 'static,
    f64: AsPrimitive<T>,
{
    let n = mat.nrows();
    let dim = mat.ncols();
    let src = mat.data();
    let mut out = vec![T::zero(); n * dim];
    if dim > 0 {
        out.par_chunks_mut(dim).enumerate().for_each(|(i, row)| {
            for (j, x) in row.iter_mut().enumerate() {
                *x = src[j * n + i].as_();
            }
        });
    }
    (out, n, dim)
}

////////////
// Output //
////////////

/// Densify a ragged kNN result into R matrices.
///
/// Short rows are padded with `NA` indices and `Inf` distances. Distances are
/// clamped at zero first, since SIMD rounding can push a self-distance just
/// below it, and that would turn into `NaN` under the square root.
///
/// ### Params
///
/// * `ids` - Ragged 0-based neighbour indices, one row per query.
/// * `dists` - Ragged distances, or `None` if the caller skipped them.
/// * `k` - Number of neighbours requested; the column count of the output.
/// * `sqrt` - Take the square root of each distance. Set for true Euclidean,
///   since the crate works in squared Euclidean.
///
/// ### Returns
///
/// `list(idx = n x k integer matrix (1-based), dist = n x k double matrix or
/// NULL)`.
pub fn pack_knn<T>(ids: Vec<Vec<usize>>, dists: Option<Vec<Vec<T>>>, k: usize, sqrt: bool) -> Robj
where
    T: Float + AsPrimitive<f64> + Send + Sync,
{
    let n = ids.len();

    let mut idx_mat = RMatrix::<i32>::new(n, k);
    if n > 0 {
        idx_mat
            .data_mut()
            .par_chunks_mut(n)
            .enumerate()
            .for_each(|(c, col)| {
                for (r, x) in col.iter_mut().enumerate() {
                    *x = ids[r].get(c).map_or(i32::MIN, |&j| (j + 1) as i32);
                }
            });
    }

    let dist_robj: Robj = match dists {
        Some(d) => {
            let mut dist_mat = RMatrix::<f64>::new(n, k);
            if n > 0 {
                dist_mat
                    .data_mut()
                    .par_chunks_mut(n)
                    .enumerate()
                    .for_each(|(c, col)| {
                        for (r, x) in col.iter_mut().enumerate() {
                            *x = d[r].get(c).map_or(f64::INFINITY, |&v| {
                                let v: f64 = v.as_().max(0.0);
                                if sqrt {
                                    v.sqrt()
                                } else {
                                    v
                                }
                            });
                        }
                    });
            }
            dist_mat.into()
        }
        None => ().into(),
    };

    list!(idx = idx_mat, dist = dist_robj).into()
}

////////////
// Errors //
////////////

/// Turn a crate error into an R error.
///
/// ### Params
///
/// * `e` - The crate error.
///
/// ### Returns
///
/// An extendr error carrying the crate's message.
pub fn r_err(e: AnnSearchErrors) -> Error {
    Error::Other(e.to_string())
}

/// Resolve an optional R integer to an optional `usize`.
///
/// ### Params
///
/// * `x` - `NULL` or a non-negative integer. Validated on the R side.
///
/// ### Returns
///
/// `None` for `NULL`, the value otherwise.
pub fn opt_usize(x: Nullable<i32>) -> Option<usize> {
    match x {
        Nullable::NotNull(v) => Some(v as usize),
        Nullable::Null => None,
    }
}
