//! Synthetic dataset generators.
//!
//! Thin wrappers over `ann_search_rs::synthetic`. They generate in f32, as the
//! Python bindings and the gridsearch examples do, so all three see identical
//! points for a given seed. The upcast to R doubles is exact.

use ann_search_rs::synthetic::{
    generate_cell_embeddings, generate_clustered_data, generate_clustered_data_high_dim,
    generate_low_rank_rotated_data, subsample_with_noise,
};
use extendr_api::prelude::*;
use faer::Mat;

/////////////
// Helpers //
/////////////

/// Move a generator result into R.
///
/// ### Params
///
/// * `data` - Column-major sample matrix from the generator.
/// * `labels` - 0-based cluster assignment per row.
///
/// ### Returns
///
/// `list(data, labels)` with an n x dim double matrix and 1-based integer
/// labels.
fn pack_dataset(data: Mat<f32>, labels: Vec<usize>) -> List {
    let data = mat_to_r(&data);
    let labels: Vec<i32> = labels.into_iter().map(|l| l as i32 + 1).collect();
    list!(data = data, labels = labels)
}

/// Copy a faer f32 matrix into an R double matrix.
///
/// ### Params
///
/// * `mat` - Column-major f32 matrix.
///
/// ### Returns
///
/// An R double matrix of the same shape.
fn mat_to_r(mat: &Mat<f32>) -> RMatrix<f64> {
    RMatrix::new_matrix(mat.nrows(), mat.ncols(), |r, c| mat[(r, c)] as f64)
}

////////////////
// Generators //
////////////////

/// Generate clustered synthetic data
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Separated Gaussian clusters joined by inter-cluster bridges. Use
/// [generate_clustered_data()] instead.
///
/// @param n Integer. Number of samples.
/// @param dim Integer. Number of features.
/// @param n_clusters Integer. Number of clusters.
/// @param seed Integer. Random seed.
///
/// @returns A list with `data` (n x dim numeric matrix) and `labels` (1-based
/// integer cluster labels).
///
/// @keywords internal
#[extendr]
fn rs_data_clustered(n: i32, dim: i32, n_clusters: i32, seed: i32) -> List {
    let (data, labels) =
        generate_clustered_data::<f32>(n as usize, dim as usize, n_clusters as usize, seed as u64);
    pack_dataset(data, labels)
}

/// Generate correlated synthetic data
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Clusters with local anisotropy plus a globally shared off-axis subspace.
/// Use [generate_correlated_data()] instead.
///
/// @param n Integer. Number of samples.
/// @param dim Integer. Number of features.
/// @param n_clusters Integer. Number of clusters.
/// @param cor_strength Numeric. Share of structured variance in the shared
/// off-axis subspace, 0 to 1.
/// @param seed Integer. Random seed.
///
/// @returns A list with `data` (n x dim numeric matrix) and `labels` (1-based
/// integer cluster labels).
///
/// @keywords internal
#[extendr]
fn rs_data_correlated(n: i32, dim: i32, n_clusters: i32, cor_strength: f64, seed: i32) -> List {
    let (data, labels) = generate_clustered_data_high_dim::<f32>(
        n as usize,
        dim as usize,
        n_clusters as usize,
        cor_strength,
        seed as u64,
    );
    pack_dataset(data, labels)
}

/// Generate low-rank synthetic data
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Cell types on a low-dimensional manifold inside a higher-dimensional
/// space, with trajectories between them. Use [generate_low_rank_data()]
/// instead.
///
/// @param n Integer. Number of samples.
/// @param dim Integer. Ambient number of features.
/// @param intrinsic_dim Integer. Dimensionality of the manifold. Must not
/// exceed `dim`; the crate panics otherwise.
/// @param n_clusters Integer. Number of cell types.
/// @param seed Integer. Random seed.
///
/// @returns A list with `data` (n x dim numeric matrix) and `labels` (1-based
/// integer cluster labels).
///
/// @keywords internal
#[extendr]
fn rs_data_low_rank(n: i32, dim: i32, intrinsic_dim: i32, n_clusters: i32, seed: i32) -> List {
    let (data, labels) = generate_low_rank_rotated_data::<f32>(
        n as usize,
        dim as usize,
        intrinsic_dim as usize,
        n_clusters as usize,
        seed as u64,
    );
    pack_dataset(data, labels)
}

/// Generate synthetic cell embeddings
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Foundation-model style cell embeddings: anisotropy cone, rogue dimensions
/// and heavy-tailed spectrum. Use [generate_cell_embeddings()] instead.
///
/// @param n Integer. Number of cells.
/// @param dim Integer. Embedding width.
/// @param n_clusters Integer. Number of cell types.
/// @param seed Integer. Random seed.
///
/// @returns A list with `data` (n x dim numeric matrix) and `labels` (1-based
/// integer cluster labels).
///
/// @keywords internal
#[extendr]
fn rs_data_cell_embeddings(n: i32, dim: i32, n_clusters: i32, seed: i32) -> List {
    let (data, labels) =
        generate_cell_embeddings::<f32>(n as usize, dim as usize, n_clusters as usize, seed as u64);
    pack_dataset(data, labels)
}

///////////////
// Utilities //
///////////////

/// Subsample queries with noise
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Draws rows from `x` and adds light Gaussian noise. Use
/// [subsample_queries()] instead.
///
/// @param x Numeric matrix, samples x features. Cast to f32.
/// @param n Integer. Rows to draw, capped at `nrow(x)`.
/// @param seed Integer. Random seed.
///
/// @returns A numeric matrix with `min(n, nrow(x))` rows.
///
/// @keywords internal
#[extendr]
fn rs_subsample_queries(x: RMatrix<f64>, n: i32, seed: i32) -> RMatrix<f64> {
    let mat = Mat::<f32>::from_fn(x.nrows(), x.ncols(), |r, c| x[[r, c]] as f32);
    mat_to_r(&subsample_with_noise(&mat, n as usize, seed as u64))
}

extendr_module! {
    mod synthetic;
    fn rs_data_clustered;
    fn rs_data_correlated;
    fn rs_data_low_rank;
    fn rs_data_cell_embeddings;
    fn rs_subsample_queries;
}
