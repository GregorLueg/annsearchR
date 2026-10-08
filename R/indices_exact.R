# exhaustive -------------------------------------------------------------------

#' Exhaustive (brute-force) index
#'
#' @description
#' Exact search: every query is compared to every indexed sample, SIMD
#' accelerated and multi-threaded. The ground truth to measure the approximate
#' indices against, and faster than you might think up to a few hundred
#' thousand samples. Large query batches go through a blocked GEMM path, which
#' on macOS runs on Apple Accelerate, so it can outrun the thread count set by
#' [ann_set_threads()].
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- ExhaustiveIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
ExhaustiveIndex <- R6::R6Class(
  "ExhaustiveIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of
    #' `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      precision = c("float", "double")
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "exhaustive"
      private$set_metric(
        metric,
        c("euclidean", "sqeuclidean", "cosine", "manhattan")
      )
      checkmate::assertChoice(precision, c("float", "double"))

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_exhaustive_build(
          .as_ann_matrix(data),
          private$core_metric,
          precision
        )
      }
      private$attach(ptr)
    }
  ),
  private = list(
    query = function(newdata, k, return_dist, verbose) {
      rs_exhaustive_query(
        private$ptr,
        newdata,
        k,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_exhaustive_self(private$ptr, k, private$sqrt, return_dist, verbose)
    }
  )
)

# kmknn ------------------------------------------------------------------------

#' kMkNN index
#'
#' @description
#' Exact search over a k-means partition, pruning whole clusters by the
#' triangle inequality. Same answers as [ExhaustiveIndex]; whether it is
#' faster depends on how well the data clusters, so time both. No Manhattan.
#'
#' @references Wang, IEEE ICDMW, 2012
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- KmknnIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
KmknnIndex <- R6::R6Class(
  "KmknnIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of `c("euclidean", "sqeuclidean", "cosine")`.
    #' @param nlist Integer or `NULL`. Number of k-means clusters. `NULL` uses
    #' `sqrt(n)`.
    #' @param kmeans_iters Integer or `NULL`. Lloyd iterations. `NULL` uses 30.
    #' @param kmeans_balanced Boolean. Reseed starved centroids each iteration.
    #' @param seed Integer. Fixes the k-means initialisation.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    #' @param .verbose Boolean. Print build progress from Rust.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      nlist = NULL,
      kmeans_iters = NULL,
      kmeans_balanced = FALSE,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "kmknn"
      private$set_metric(metric, c("euclidean", "sqeuclidean", "cosine"))
      nlist <- .as_knob(nlist, .var.name = "nlist")
      kmeans_iters <- .as_knob(kmeans_iters, .var.name = "kmeans_iters")
      checkmate::qassert(kmeans_balanced, "B1")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))
      checkmate::qassert(.verbose, "B1")

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_kmknn_build(
          .as_ann_matrix(data),
          private$core_metric,
          nlist,
          kmeans_iters,
          kmeans_balanced,
          as.integer(seed),
          precision,
          .verbose
        )
      }
      private$attach(ptr)
    }
  ),
  private = list(
    query = function(newdata, k, return_dist, verbose) {
      rs_kmknn_query(
        private$ptr,
        newdata,
        k,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_kmknn_self(private$ptr, k, private$sqrt, return_dist, verbose)
    }
  )
)
