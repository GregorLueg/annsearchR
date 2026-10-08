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

# nndescent --------------------------------------------------------------------

#' NN-Descent index
#'
#' @description
#' Builds the kNN graph directly by iterative local join. Want the kNN graph of
#' the data itself (UMAP, clustering)? `$extract_knn()` hands back the
#' converged graph without any search, far cheaper than `$query_self()`. It
#' reads the post-pruning graph, so leave `diversify_prob` at 0 if extraction
#' is the point.
#'
#' @references Dong, Moses & Li, WWW, 2011
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- NNDescentIndex$new(x, k_graph = 15L)
#' knn <- idx$extract_knn()
#'
#' @export
NNDescentIndex <- R6::R6Class(
  "NNDescentIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of
    #' `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.
    #' @param k_graph Integer. Neighbours per node in the graph being built.
    #' @param delta Numeric. Convergence threshold: descent stops once the
    #' fraction of updated edges falls below it.
    #' @param diversify_prob Numeric between 0 and 1. Probability of pruning an
    #' occluded edge after descent. `0` disables pruning.
    #' @param max_iter Integer or `NULL`. Iteration cap. `NULL` uses
    #' `max(round(log2(n)), 5)`.
    #' @param max_candidates Integer or `NULL`. Neighbours sampled per node per
    #' local join. `NULL` uses `min(k_graph, 60)`.
    #' @param n_trees Integer or `NULL`. Random projection trees for the seed
    #' graph. `NULL` uses `min(5 + round(n^0.25), 12)`.
    #' @param ef_search Integer or `NULL`. Beam width at query time. `NULL`
    #' uses `clamp(2 * k, 50, 200)`. Can be changed after the build.
    #' @param seed Integer. Fixes the seed graph and the sampling.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    #' @param .verbose Boolean. Print build progress from Rust.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      k_graph = 15L,
      delta = 0.001,
      diversify_prob = 0,
      max_iter = NULL,
      max_candidates = NULL,
      n_trees = NULL,
      ef_search = NULL,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "nndescent"
      private$set_metric(
        metric,
        c("euclidean", "sqeuclidean", "cosine", "manhattan")
      )
      checkmate::qassert(k_graph, "X1[1,)")
      checkmate::qassert(delta, "N1[0,1]")
      checkmate::qassert(diversify_prob, "N1[0,1]")
      max_iter <- .as_knob(max_iter, .var.name = "max_iter")
      max_candidates <- .as_knob(max_candidates, .var.name = "max_candidates")
      n_trees <- .as_knob(n_trees, .var.name = "n_trees")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))
      checkmate::qassert(.verbose, "B1")

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_nndescent_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(k_graph),
          as.double(delta),
          as.double(diversify_prob),
          max_iter,
          max_candidates,
          n_trees,
          as.integer(seed),
          precision,
          .verbose
        )
      }
      private$attach(ptr)
      private$.k_graph <- as.integer(k_graph)
      self$ef_search <- ef_search
    },

    #' @description
    #' The converged kNN graph over the indexed data, read straight off the
    #' index. No search involved.
    #'
    #' @param k Integer or `NULL`. Row length, including the sample itself when
    #' `include_self = TRUE`. `NULL` uses the graph degree `k_graph`.
    #' @param include_self Boolean. Put each sample first at distance 0, as
    #' `$query_self()` does.
    #' @param return_dist Boolean. Return the distances as well.
    #'
    #' @returns A list with `idx` and `dist`, as for `$predict()`, with one row
    #' per indexed sample. Rows the graph cannot fill are `NA` padded.
    extract_knn = function(k = NULL, include_self = TRUE, return_dist = TRUE) {
      private$check_ptr()
      k <- .as_knob(k, .var.name = "k")
      checkmate::qassert(include_self, "B1")
      checkmate::qassert(return_dist, "B1")
      if (is.null(k)) {
        k <- private$.k_graph
      }
      rs_nndescent_extract(
        private$ptr,
        k,
        include_self,
        private$sqrt,
        return_dist
      )
    }
  ),
  active = list(
    #' @field ef_search Integer or `NULL`. Beam width at query time.
    ef_search = function(value) {
      if (missing(value)) {
        return(private$.ef_search)
      }
      private$.ef_search <- .as_knob(value, .var.name = "ef_search")
    },
    #' @field k_graph Integer. Degree of the built graph. Read-only.
    k_graph = function(value) {
      if (!missing(value)) {
        stop("`k_graph` is read-only.")
      }
      private$.k_graph
    }
  ),
  private = list(
    .ef_search = NULL,
    .k_graph = NULL,
    knobs = function() {
      list(k_graph = private$.k_graph, ef_search = private$.ef_search)
    },
    query = function(newdata, k, return_dist, verbose) {
      rs_nndescent_query(
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
      rs_nndescent_self(
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

# vamana -----------------------------------------------------------------------

#' Vamana index
#'
#' @description
#' The flat graph from DiskANN: out-degree `r`, pruned in two passes with the
#' relaxed-neighbour rule. Builds slower than [HnswIndex] at its cheapest
#' setting, though the gap closes once you match on recall, and the index is a
#' few per cent smaller.
#'
#' @references Subramanya et al., NeurIPS, 2019
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- VamanaIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
VamanaIndex <- R6::R6Class(
  "VamanaIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of
    #' `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.
    #' @param r Integer. Maximum out-degree.
    #' @param l_build Integer. Candidate list width during the build.
    #' @param alpha_pass1 Numeric. Relaxed-neighbour factor on the first
    #' pruning pass. `1` is the plain rule.
    #' @param alpha_pass2 Numeric. Same on the second pass. Above 1 keeps
    #' longer edges, which keeps the graph navigable from far away.
    #' @param ef_search Integer or `NULL`. Beam width at query time. `NULL`
    #' uses 75. Can be changed after the build.
    #' @param seed Integer. Fixes the entry point and pruning order.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      r = 48L,
      l_build = 100L,
      alpha_pass1 = 1.0,
      alpha_pass2 = 1.2,
      ef_search = NULL,
      seed = 42L,
      precision = c("float", "double")
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "vamana"
      private$set_metric(
        metric,
        c("euclidean", "sqeuclidean", "cosine", "manhattan")
      )
      checkmate::qassert(r, "X1[2,)")
      checkmate::qassert(l_build, "X1[1,)")
      checkmate::qassert(alpha_pass1, "N1[1,)")
      checkmate::qassert(alpha_pass2, "N1[1,)")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_vamana_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(r),
          as.integer(l_build),
          as.double(alpha_pass1),
          as.double(alpha_pass2),
          as.integer(seed),
          precision
        )
      }
      private$attach(ptr)
      self$ef_search <- ef_search
    }
  ),
  active = list(
    #' @field ef_search Integer or `NULL`. Beam width at query time.
    ef_search = function(value) {
      if (missing(value)) {
        return(private$.ef_search)
      }
      private$.ef_search <- .as_knob(value, .var.name = "ef_search")
    }
  ),
  private = list(
    .ef_search = NULL,
    knobs = function() list(ef_search = private$.ef_search),
    query = function(newdata, k, return_dist, verbose) {
      rs_vamana_query(
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
      rs_vamana_self(
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

# nsg --------------------------------------------------------------------------

#' NSG index
#'
#' @description
#' Navigating spreading-out graph. Builds an NN-Descent kNN graph of degree
#' `knn_k` first, then refines it into a sparse monotonic graph. Smallest of
#' the graph indices; pays for it with a double build.
#'
#' @references Fu et al., VLDB, 2019
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- NsgIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
NsgIndex <- R6::R6Class(
  "NsgIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of
    #' `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.
    #' @param r Integer. Maximum out-degree of the refined graph.
    #' @param l_build Integer. Candidate list width while refining.
    #' @param c Integer. Candidate pool size per node before pruning.
    #' @param knn_k Integer. Degree of the NN-Descent graph built first. Wants
    #' to be comfortably above `r`.
    #' @param ef_search Integer or `NULL`. Beam width at query time. `NULL`
    #' uses 100. Can be changed after the build.
    #' @param seed Integer. Fixes the initial graph and navigating node.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    #' @param .verbose Boolean. Print build progress from Rust.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      r = 32L,
      l_build = 100L,
      c = 500L,
      knn_k = 64L,
      ef_search = NULL,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "nsg"
      private$set_metric(
        metric,
        c("euclidean", "sqeuclidean", "cosine", "manhattan")
      )
      checkmate::qassert(r, "X1[2,)")
      checkmate::qassert(l_build, "X1[1,)")
      checkmate::qassert(c, "X1[1,)")
      checkmate::qassert(knn_k, "X1[1,)")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))
      checkmate::qassert(.verbose, "B1")

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_nsg_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(r),
          as.integer(l_build),
          as.integer(c),
          as.integer(knn_k),
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
    #' @field ef_search Integer or `NULL`. Beam width at query time.
    ef_search = function(value) {
      if (missing(value)) {
        return(private$.ef_search)
      }
      private$.ef_search <- .as_knob(value, .var.name = "ef_search")
    }
  ),
  private = list(
    .ef_search = NULL,
    knobs = function() list(ef_search = private$.ef_search),
    query = function(newdata, k, return_dist, verbose) {
      rs_nsg_query(
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
      rs_nsg_self(
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

# rnn descent ------------------------------------------------------------------

#' Relative NN-Descent index
#'
#' @description
#' Builds and prunes a navigable graph in one pass, skipping the separate
#' refinement step [NsgIndex] pays for. `r` caps the out-degree, `ef_search`
#' is the recall knob. On Gaussian benchmark data it tops out around 0.97
#' recall, so check it reaches what you need.
#'
#' @references Ono & Matsui, ACM MM, 2023
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- RnnDescentIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
RnnDescentIndex <- R6::R6Class(
  "RnnDescentIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of
    #' `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.
    #' @param s Integer. Neighbours sampled per node per local join.
    #' @param r Integer. Maximum out-degree after pruning.
    #' @param t1 Integer. Outer iterations.
    #' @param t2 Integer. Inner descent iterations per outer one.
    #' @param n_trees Integer or `NULL`. Random projection trees for the seed
    #' graph. `NULL` uses `min(5 + n^0.25 / 2, 16)`.
    #' @param ef_search Integer or `NULL`. Beam width at query time. `NULL`
    #' uses 100. Can be changed after the build.
    #' @param k_search Integer or `NULL`. Neighbours expanded per hop. `NULL`
    #' uses 32, capped at `r`. Can be changed after the build.
    #' @param seed Integer. Fixes the seed graph and the sampling.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    #' @param .verbose Boolean. Print build progress from Rust.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      s = 20L,
      r = 96L,
      t1 = 4L,
      t2 = 15L,
      n_trees = NULL,
      ef_search = NULL,
      k_search = NULL,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "rnndescent"
      private$set_metric(
        metric,
        c("euclidean", "sqeuclidean", "cosine", "manhattan")
      )
      checkmate::qassert(s, "X1[1,)")
      checkmate::qassert(r, "X1[2,)")
      checkmate::qassert(t1, "X1[1,)")
      checkmate::qassert(t2, "X1[1,)")
      n_trees <- .as_knob(n_trees, .var.name = "n_trees")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))
      checkmate::qassert(.verbose, "B1")

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_rnndescent_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(s),
          as.integer(r),
          as.integer(t1),
          as.integer(t2),
          n_trees,
          as.integer(seed),
          precision,
          .verbose
        )
      }
      private$attach(ptr)
      self$ef_search <- ef_search
      self$k_search <- k_search
    }
  ),
  active = list(
    #' @field ef_search Integer or `NULL`. Beam width at query time.
    ef_search = function(value) {
      if (missing(value)) {
        return(private$.ef_search)
      }
      private$.ef_search <- .as_knob(value, .var.name = "ef_search")
    },
    #' @field k_search Integer or `NULL`. Neighbours expanded per hop.
    k_search = function(value) {
      if (missing(value)) {
        return(private$.k_search)
      }
      private$.k_search <- .as_knob(value, .var.name = "k_search")
    }
  ),
  private = list(
    .ef_search = NULL,
    .k_search = NULL,
    knobs = function() {
      list(ef_search = private$.ef_search, k_search = private$.k_search)
    },
    query = function(newdata, k, return_dist, verbose) {
      rs_rnndescent_query(
        private$ptr,
        newdata,
        k,
        private$.ef_search,
        private$.k_search,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_rnndescent_self(
        private$ptr,
        k,
        private$.ef_search,
        private$.k_search,
        private$sqrt,
        return_dist,
        verbose
      )
    }
  )
)
