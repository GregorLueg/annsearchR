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
pub mod ball_tree;
pub mod exhaustive;
pub mod hnsw;
pub mod ivf;
pub mod kd_tree;
pub mod kmknn;
pub mod lsh;
pub mod nndescent;
pub mod nsg;
pub mod rnn_descent;
pub mod soar;
pub mod vamana;

use extendr_api::prelude::*;

extendr_module! {
    mod annsearchR;
    use handle;
    use pool;
    use utils;
    use exhaustive;
    use kmknn;
    use annoy;
    use kd_tree;
    use ball_tree;
    use hnsw;
    use ivf;
    use soar;
    use lsh;
    use nndescent;
    use vamana;
    use nsg;
    use rnn_descent;
}
