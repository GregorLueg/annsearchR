//! R bindings for the CPU indices of `ann-search-rs`.
//!
//! Every index lives behind one `ExternalPtr<AnnIndex>` (see [`handle`]). Each
//! algorithm module exposes `rs_<algo>_build`, `rs_<algo>_query` and
//! `rs_<algo>_self`; the R6 classes in `R/` are the user-facing layer.

pub mod convert;
pub mod handle;
pub mod pool;
pub mod utils;

pub mod annoy;
pub mod exhaustive;
pub mod hnsw;

use extendr_api::prelude::*;

extendr_module! {
    mod annsearchR;
    use handle;
    use pool;
    use utils;
    use exhaustive;
    use annoy;
    use hnsw;
}
