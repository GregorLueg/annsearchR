# generators -------------------------------------------------------------------

#' Generate clustered synthetic data
#'
#' @description
#' Separated Gaussian clusters, with a fifth of the points on thin bridges
#' between neighbouring clusters so the boundaries aren't trivially clean. The
#' baseline of the four generators.
#'
#' All generators are the ones behind the Rust crate's benchmark tables. They
#' draw in f32 like the crate's gridsearch examples and the Python bindings,
#' so the same seed gives the same points in all three.
#'
#' @param n Integer. Number of samples.
#' @param dim Integer. Number of features.
#' @param n_clusters Integer. Number of clusters.
#' @param seed Integer. Random seed.
#'
#' @returns A list with:
#' \itemize{
#'   \item data - Numeric matrix, n x dim.
#'   \item labels - Integer vector of 1-based cluster labels.
#' }
#'
#' @examples
#' dat <- generate_clustered_data(1000L, 16L, n_clusters = 5L)
#' table(dat$labels)
#'
#' @export
generate_clustered_data <- function(n, dim, n_clusters = 25L, seed = 42L) {
  checkmate::qassert(n, "X1[1,)")
  checkmate::qassert(dim, "X1[1,)")
  checkmate::qassert(n_clusters, "X1[1,)")
  checkmate::qassert(seed, "X1[0,)")
  rs_data_clustered(
    as.integer(n),
    as.integer(dim),
    as.integer(n_clusters),
    as.integer(seed)
  )
}

#' Generate correlated synthetic data
#'
#' @description
#' Well-separated clusters, each an arbitrarily oriented ellipsoid, plus a
#' globally shared off-axis subspace that correlates the features. None of the
#' structured variance lines up with the coordinate axes, and bridges between
#' neighbouring clusters keep the blobs reachable for graph indices.
#'
#' @inheritParams generate_clustered_data
#' @param cor_strength Numeric. Share of the structured variance in the shared
#' off-axis subspace, between 0 (all cluster-local) and 1 (all shared). 0.5 is
#' the value behind the crate's benchmark tables.
#'
#' @inherit generate_clustered_data return
#'
#' @examples
#' dat <- generate_correlated_data(1000L, 32L, n_clusters = 5L)
#'
#' @export
generate_correlated_data <- function(
  n,
  dim,
  n_clusters = 25L,
  cor_strength = 0.5,
  seed = 42L
) {
  checkmate::qassert(n, "X1[1,)")
  checkmate::qassert(dim, "X1[1,)")
  checkmate::qassert(n_clusters, "X1[1,)")
  checkmate::qassert(cor_strength, "N1[0,1]")
  checkmate::qassert(seed, "X1[0,)")
  rs_data_correlated(
    as.integer(n),
    as.integer(dim),
    as.integer(n_clusters),
    as.double(cor_strength),
    as.integer(seed)
  )
}

#' Generate low-rank synthetic data
#'
#' @description
#' Cell types on an `intrinsic_dim`-dimensional manifold, isometrically
#' embedded in `dim` ambient dimensions with a touch of noise. Types are
#' grouped into lineages, with curved differentiation trajectories running
#' between types of the same lineage.
#'
#' @inheritParams generate_clustered_data
#' @param intrinsic_dim Integer. True dimensionality of the manifold. Must not
#' exceed `dim`.
#'
#' @inherit generate_clustered_data return
#'
#' @examples
#' dat <- generate_low_rank_data(1000L, 64L, intrinsic_dim = 8L)
#'
#' @export
generate_low_rank_data <- function(
  n,
  dim,
  n_clusters = 25L,
  intrinsic_dim = 16L,
  seed = 42L
) {
  checkmate::qassert(n, "X1[1,)")
  checkmate::qassert(dim, "X1[1,)")
  checkmate::qassert(n_clusters, "X1[1,)")
  checkmate::qassert(intrinsic_dim, "X1[1,)")
  checkmate::qassert(seed, "X1[0,)")
  # the crate asserts this and would panic
  if (intrinsic_dim > dim) {
    stop(sprintf(
      "`intrinsic_dim` (%d) cannot exceed `dim` (%d).",
      as.integer(intrinsic_dim),
      as.integer(dim)
    ))
  }
  rs_data_low_rank(
    as.integer(n),
    as.integer(dim),
    as.integer(intrinsic_dim),
    as.integer(n_clusters),
    as.integer(seed)
  )
}

#' Generate synthetic cell embeddings
#'
#' @description
#' Foundation-model cell embeddings in the style of Geneformer or scGPT. A
#' large shared mean offset puts every cell inside an anisotropy cone, a few
#' axis-aligned rogue dimensions dominate dot products, each cell type varies
#' in its own low-rank subspace, and a per-cell scale stands in for library
#' size. The nastiest of the four generators.
#'
#' @inheritParams generate_clustered_data
#'
#' @inherit generate_clustered_data return
#'
#' @examples
#' dat <- generate_cell_embeddings(1000L, 64L, n_clusters = 8L)
#'
#' @export
generate_cell_embeddings <- function(n, dim, n_clusters = 25L, seed = 42L) {
  checkmate::qassert(n, "X1[1,)")
  checkmate::qassert(dim, "X1[1,)")
  checkmate::qassert(n_clusters, "X1[1,)")
  checkmate::qassert(seed, "X1[0,)")
  rs_data_cell_embeddings(
    as.integer(n),
    as.integer(dim),
    as.integer(n_clusters),
    as.integer(seed)
  )
}

# queries ----------------------------------------------------------------------

#' Subsample queries from a dataset
#'
#' @description
#' Draws rows from `x` and adds light Gaussian noise (sd 0.05). Querying an
#' index with the rows it was built from flatters it: every query has an exact
#' hit at distance zero. This puts the queries near the data instead of on it.
#' The data is cast to f32 first, as in the Python bindings.
#'
#' @param x Numeric matrix, samples x features.
#' @param n Integer. Number of rows to draw, capped at `nrow(x)`.
#' @param seed Integer. Random seed for the draw and the noise.
#'
#' @returns Numeric matrix with `min(n, nrow(x))` rows and `ncol(x)` columns.
#'
#' @examples
#' dat <- generate_clustered_data(1000L, 16L)$data
#' query <- subsample_queries(dat, 100L)
#'
#' @export
subsample_queries <- function(x, n, seed = 42L) {
  checkmate::assertMatrix(
    x,
    mode = "numeric",
    any.missing = FALSE,
    min.rows = 1L,
    min.cols = 1L
  )
  checkmate::qassert(n, "X1[1,)")
  checkmate::qassert(seed, "X1[0,)")
  storage.mode(x) <- "double"
  rs_subsample_queries(x, as.integer(n), as.integer(seed))
}
