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

# annoy ------------------------------------------------------------------------

#' Annoy index
#'
#' @description
#' Random projection forest, as in Spotify's Annoy. More trees means better
#' recall, a larger index and a slower build. Raise `search_budget` for recall
#' at query time. No Manhattan.
#'
#' @references Bernhardsson, Annoy, <https://github.com/spotify/annoy>
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- AnnoyIndex$new(x, n_trees = 25L)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
AnnoyIndex <- R6::R6Class(
  "AnnoyIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of `c("euclidean", "sqeuclidean", "cosine")`.
    #' @param n_trees Integer. Number of trees in the forest.
    #' @param search_budget Integer or `NULL`. Candidates inspected per query.
    #' `NULL` uses `k * n_trees * 20`. Can be changed after the build.
    #' @param seed Integer. Fixes the random hyperplanes.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      n_trees = 25L,
      search_budget = NULL,
      seed = 42L,
      precision = c("float", "double")
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "annoy"
      private$set_metric(metric, c("euclidean", "sqeuclidean", "cosine"))
      checkmate::qassert(n_trees, "X1[1,)")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_annoy_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(n_trees),
          as.integer(seed),
          precision
        )
      }
      private$attach(ptr)
      self$search_budget <- search_budget
    }
  ),
  active = list(
    #' @field search_budget Integer or `NULL`. Candidates inspected per query.
    search_budget = function(value) {
      if (missing(value)) {
        return(private$.search_budget)
      }
      private$.search_budget <- .as_knob(value, .var.name = "search_budget")
    }
  ),
  private = list(
    .search_budget = NULL,
    knobs = function() list(search_budget = private$.search_budget),
    query = function(newdata, k, return_dist, verbose) {
      rs_annoy_query(
        private$ptr,
        newdata,
        k,
        private$.search_budget,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_annoy_self(
        private$ptr,
        k,
        private$.search_budget,
        private$sqrt,
        return_dist,
        verbose
      )
    }
  )
)

# hnsw -------------------------------------------------------------------------

#' HNSW index
#'
#' @description
#' Hierarchical navigable small world graph. The usual first choice: high
#' recall at low query latency. Raise `ef_search` for recall at query time,
#' `ef_construction` for a better graph at build time.
#'
#' Nodes are inserted in parallel, so two builds with the same `seed` give
#' slightly different graphs. Need bit-identical results? Build with
#' `ann_set_threads(1L)`.
#'
#' @references Malkov & Yashunin, IEEE TPAMI, 2020
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- HnswIndex$new(x, metric = "cosine")
#' idx$ef_search <- 100L
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
HnswIndex <- R6::R6Class(
  "HnswIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of
    #' `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.
    #' @param m Integer. Edges per node on the upper layers, `2 * m` on layer
    #' 0. 16 suits most data; 32 to 48 helps in high dimensions.
    #' @param ef_construction Integer. Candidate list width during the build.
    #' Better graph, slower build, no cost at query time.
    #' @param ef_search Integer. Beam width at query time. Raised to `k`
    #' internally if smaller. Can be changed after the build.
    #' @param seed Integer. Fixes the layer assignment.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    #' @param .verbose Boolean. Print build progress from Rust.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      m = 16L,
      ef_construction = 200L,
      ef_search = 50L,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "hnsw"
      private$set_metric(
        metric,
        c("euclidean", "sqeuclidean", "cosine", "manhattan")
      )
      checkmate::qassert(m, "X1[2,)")
      checkmate::qassert(ef_construction, "X1[1,)")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))
      checkmate::qassert(.verbose, "B1")

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_hnsw_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(m),
          as.integer(ef_construction),
          as.integer(seed),
          precision,
          .verbose
        )
      }
      private$attach(ptr)
      self$ef_search <- ef_search
    }
  ),
  active = list(
    #' @field ef_search Integer. Beam width at query time.
    ef_search = function(value) {
      if (missing(value)) {
        return(private$.ef_search)
      }
      private$.ef_search <- .as_knob(
        value,
        null_ok = FALSE,
        .var.name = "ef_search"
      )
    }
  ),
  private = list(
    .ef_search = NULL,
    knobs = function() list(ef_search = private$.ef_search),
    query = function(newdata, k, return_dist, verbose) {
      rs_hnsw_query(
        private$ptr,
        newdata,
        k,
        private$.ef_search,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_hnsw_self(
        private$ptr,
        k,
        private$.ef_search,
        private$sqrt,
        return_dist,
        verbose
      )
    }
  )
)
