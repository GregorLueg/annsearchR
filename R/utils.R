# threads ----------------------------------------------------------------------

#' Set the number of threads for index builds and queries
#'
#' @description
#' Installs a dedicated thread pool for all subsequent builds and queries.
#' Can be called as often as you like.
#'
#' @param n Integer. Number of threads. `0L` returns to the default pool,
#' which uses all cores or honours `RAYON_NUM_THREADS` if set.
#'
#' @returns The previous thread count, invisibly.
#'
#' @export
ann_set_threads <- function(n) {
  checkmate::qassert(n, "X1[0,)")
  old <- rs_get_threads()
  rs_set_threads(as.integer(n))
  invisible(old)
}

#' Number of threads used for index builds and queries
#'
#' @returns Integer.
#'
#' @export
ann_get_threads <- function() {
  rs_get_threads()
}

# recall -----------------------------------------------------------------------

#' Recall of an approximate kNN result
#'
#' @description
#' Fraction of the true `k` nearest neighbours that the approximate search
#' found, averaged over queries. Order within a row does not matter.
#'
#' @param truth Integer matrix. Queries x k true neighbour indices, e.g. the
#' `idx` element from an [ExhaustiveIndex].
#' @param approx Integer matrix. Queries x k approximate neighbour indices.
#' @param k Optional integer. Only the first `k` columns of both are compared.
#' Defaults to `ncol(approx)`.
#'
#' @returns Numeric between 0 and 1.
#'
#' @export
knn_recall <- function(truth, approx, k = NULL) {
  checkmate::assertMatrix(truth, mode = "numeric", min.cols = 1L)
  checkmate::assertMatrix(
    approx,
    mode = "numeric",
    nrows = nrow(truth),
    min.cols = 1L
  )
  checkmate::qassert(k, c("0", "X1[1,)"))
  k <- if (is.null(k)) ncol(approx) else as.integer(k)
  if (k > ncol(truth) || k > ncol(approx)) {
    stop("`k` is larger than the number of columns in `truth` or `approx`.")
  }
  truth <- truth[, seq_len(k), drop = FALSE]
  approx <- approx[, seq_len(k), drop = FALSE]
  storage.mode(truth) <- "integer"
  storage.mode(approx) <- "integer"
  rs_knn_recall(truth, approx)
}
