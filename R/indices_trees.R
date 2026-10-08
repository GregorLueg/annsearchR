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

# kd tree ----------------------------------------------------------------------

#' kd forest index
#'
#' @description
#' Forest of randomised kd spill-trees. Same trade as [AnnoyIndex] with
#' axis-aligned splits instead of random hyperplanes: more trees means better
#' recall and a larger index. Points near a split land in both children, which
#' lets one descent recover neighbours a hard split would separate. The one
#' tree index here that supports Manhattan.
#'
#' @references Muja & Lowe, IEEE TPAMI, 2014
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- KdTreeIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
KdTreeIndex <- R6::R6Class(
  "KdTreeIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of
    #' `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.
    #' @param n_trees Integer. Number of trees in the forest.
    #' @param search_budget Integer or `NULL`. Candidates inspected per query.
    #' `NULL` uses `k * n_trees * 20`. Can be changed after the build.
    #' @param seed Integer. Fixes the split dimensions.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      n_trees = 25L,
      search_budget = NULL,
      seed = 42L,
      precision = c("float", "double")
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "kdtree"
      private$set_metric(
        metric,
        c("euclidean", "sqeuclidean", "cosine", "manhattan")
      )
      checkmate::qassert(n_trees, "X1[1,)")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_kdtree_build(
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
      rs_kdtree_query(
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
      rs_kdtree_self(
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

# ball tree --------------------------------------------------------------------

#' Ball tree index
#'
#' @description
#' Metric tree of nested hyperspheres, pruned by the triangle inequality. Pays
#' off on data with real cluster structure at moderate dimensionality. The
#' default search budget (5% of the indexed points) makes it approximate; raise
#' it for recall. Past about 10% recall plateaus and query time does not fall.
#' No Manhattan.
#'
#' @references Omohundro, ICSI Technical Report, 1989
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- BallTreeIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
BallTreeIndex <- R6::R6Class(
  "BallTreeIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of `c("euclidean", "sqeuclidean", "cosine")`.
    #' @param search_budget Integer or `NULL`. Points inspected per query.
    #' `NULL` uses 5% of the indexed points. Can be changed after the build.
    #' @param seed Integer. Fixes the pivot choice at each split.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      search_budget = NULL,
      seed = 42L,
      precision = c("float", "double")
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "balltree"
      private$set_metric(metric, c("euclidean", "sqeuclidean", "cosine"))
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_balltree_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(seed),
          precision
        )
      }
      private$attach(ptr)
      self$search_budget <- search_budget
    }
  ),
  active = list(
    #' @field search_budget Integer or `NULL`. Points inspected per query.
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
      rs_balltree_query(
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
      rs_balltree_self(
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
