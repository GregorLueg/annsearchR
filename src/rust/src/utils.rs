//! Helpers outside any single index: recall against ground truth and the
//! crate's synthetic data generator.

use ann_search_rs::prelude::KMeansTrainingParams;
use ann_search_rs::synthetic::generate_clustered_data;
use extendr_api::prelude::*;
use extendr_api::{Error, Result};
use faer::Mat;
use rayon::prelude::*;

/// Assemble k-means training parameters for the IVF-family builders.
///
/// `None` lets the crate pick its own heuristic, which is not the same as
/// passing its defaults explicitly, so a struct is only built when the caller
/// asked for something.
///
/// ### Params
///
/// * `iters` - Lloyd iterations, or `None` for the crate default.
/// * `balanced` - Reseed starved centroids each iteration.
///
/// ### Returns
///
/// `None` if nothing was asked for, the parameters otherwise.
pub fn kmeans_params(iters: Option<usize>, balanced: bool) -> Option<KMeansTrainingParams> {
    if iters.is_none() && !balanced {
        return None;
    }
    let base = match iters {
        Some(i) => KMeansTrainingParams::new(i, None, None),
        None => KMeansTrainingParams::default(),
    };
    Some(base.with_balancing(balanced))
}

/// Recall of an approximate kNN result against ground truth
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [knn_recall()] instead.
///
/// @param truth Integer matrix. Queries x k true neighbour indices.
/// @param approx Integer matrix. Queries x k approximate neighbour indices,
/// same shape as `truth`.
///
/// @returns Numeric. Mean over queries of |truth ∩ approx| / k. `NA` entries in
/// `approx` never count as hits.
///
/// @keywords internal
#[extendr]
fn rs_knn_recall(truth: RMatrix<i32>, approx: RMatrix<i32>) -> Result<f64> {
    let (n, k) = (truth.nrows(), truth.ncols());
    if approx.nrows() != n || approx.ncols() != k {
        return Err(Error::Other(
            "truth and approx must have the same shape".into(),
        ));
    }
    if n == 0 || k == 0 {
        return Ok(f64::NAN);
    }
    let (t, a) = (truth.data(), approx.data());

    let hits: usize = (0..n)
        .into_par_iter()
        .map(|r| {
            (0..k)
                .filter(|&c| {
                    let v = a[c * n + r];
                    v != i32::MIN && (0..k).any(|tc| t[tc * n + r] == v)
                })
                .count()
        })
        .sum();

    Ok(hits as f64 / (n * k) as f64)
}

/// Generate clustered synthetic data
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Gaussian clusters with random centres and per-cluster spread, the same
/// generator the crate's own benchmarks use. Use
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
    let (mat, labels): (Mat<f64>, Vec<usize>) =
        generate_clustered_data(n as usize, dim as usize, n_clusters as usize, seed as u64);
    let data = RMatrix::new_matrix(mat.nrows(), mat.ncols(), |r, c| mat[(r, c)]);
    let labels: Vec<i32> = labels.into_iter().map(|l| l as i32 + 1).collect();
    list!(data = data, labels = labels)
}

extendr_module! {
    mod utils;
    fn rs_knn_recall;
    fn rs_data_clustered;
}
