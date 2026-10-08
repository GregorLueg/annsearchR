# ivf --------------------------------------------------------------------------

#' IVF index
#'
#' @description
#' Inverted file over k-means Voronoi cells. Cheap to build and easy to tune:
#' `nlist` sets how finely the space is cut, `nprobe` how many cells a query
#' visits. The smallest of the unquantised approximate indices. No Manhattan.
#'
#' @references Jégou, Douze & Schmid, IEEE TPAMI, 2011
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- IvfIndex$new(x)
#' idx$nprobe <- 10L
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
IvfIndex <- R6::R6Class(
  "IvfIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of `c("euclidean", "sqeuclidean", "cosine")`.
    #' @param nlist Integer or `NULL`. Number of Voronoi cells. `NULL` uses
    #' `sqrt(n)`.
    #' @param nprobe Integer or `NULL`. Cells visited per query. `NULL` uses
    #' `sqrt(nlist)`. Can be changed after the build.
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
      nprobe = NULL,
      kmeans_iters = NULL,
      kmeans_balanced = FALSE,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "ivf"
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
        rs_ivf_build(
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
      self$nprobe <- nprobe
    }
  ),
  active = list(
    #' @field nprobe Integer or `NULL`. Cells visited per query.
    nprobe = function(value) {
      if (missing(value)) {
        return(private$.nprobe)
      }
      private$.nprobe <- .as_knob(value, .var.name = "nprobe")
    }
  ),
  private = list(
    .nprobe = NULL,
    knobs = function() list(nprobe = private$.nprobe),
    query = function(newdata, k, return_dist, verbose) {
      rs_ivf_query(
        private$ptr,
        newdata,
        k,
        private$.nprobe,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_ivf_self(
        private$ptr,
        k,
        private$.nprobe,
        private$sqrt,
        return_dist,
        verbose
      )
    }
  )
)

# soar -------------------------------------------------------------------------

#' SOAR index
#'
#' @description
#' IVF with spilling: every point also lands in a second cell, picked by a rule
#' that accounts for the residual it carries in its first. Buys recall at a
#' given `nprobe` over [IvfIndex], but scans about twice the candidates per
#' probe, so compare the two on query time, not on `nprobe`. No Manhattan.
#'
#' @references Sun et al., NeurIPS, 2023
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- SoarIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
SoarIndex <- R6::R6Class(
  "SoarIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of `c("euclidean", "sqeuclidean", "cosine")`.
    #' @param nlist Integer or `NULL`. Number of Voronoi cells. `NULL` uses
    #' `sqrt(n)`.
    #' @param nprobe Integer or `NULL`. Cells visited per query. `NULL` uses
    #' `sqrt(nlist)`. Can be changed after the build.
    #' @param rule String or `NULL`. Secondary assignment rule, one of
    #' `c("nearest", "shifted", "orthogonal")`. `NULL` picks orthogonal for
    #' cosine and shifted otherwise.
    #' @param rule_param Numeric or `NULL`. `mu` for the shifted rule, `lambda`
    #' for the orthogonal one. `NULL` uses 0.5 and 1.0 respectively.
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
      nprobe = NULL,
      rule = NULL,
      rule_param = NULL,
      kmeans_iters = NULL,
      kmeans_balanced = FALSE,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "soar"
      private$set_metric(metric, c("euclidean", "sqeuclidean", "cosine"))
      nlist <- .as_knob(nlist, .var.name = "nlist")
      checkmate::assertChoice(
        rule,
        c("nearest", "shifted", "orthogonal"),
        null.ok = TRUE
      )
      checkmate::qassert(rule_param, c("0", "N1(0,)"))
      kmeans_iters <- .as_knob(kmeans_iters, .var.name = "kmeans_iters")
      checkmate::qassert(kmeans_balanced, "B1")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))
      checkmate::qassert(.verbose, "B1")

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_soar_build(
          .as_ann_matrix(data),
          private$core_metric,
          nlist,
          rule,
          if (is.null(rule_param)) NULL else as.double(rule_param),
          kmeans_iters,
          kmeans_balanced,
          as.integer(seed),
          precision,
          .verbose
        )
      }
      private$attach(ptr)
      self$nprobe <- nprobe
    }
  ),
  active = list(
    #' @field nprobe Integer or `NULL`. Cells visited per query.
    nprobe = function(value) {
      if (missing(value)) {
        return(private$.nprobe)
      }
      private$.nprobe <- .as_knob(value, .var.name = "nprobe")
    }
  ),
  private = list(
    .nprobe = NULL,
    knobs = function() list(nprobe = private$.nprobe),
    query = function(newdata, k, return_dist, verbose) {
      rs_soar_query(
        private$ptr,
        newdata,
        k,
        private$.nprobe,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_soar_self(
        private$ptr,
        k,
        private$.nprobe,
        private$sqrt,
        return_dist,
        verbose
      )
    }
  )
)

# lsh --------------------------------------------------------------------------

#' LSH index
#'
#' @description
#' Multi-probe locality-sensitive hashing over random projections. By far the
#' cheapest index to build here, and the weakest on recall for the query time
#' it costs; the one index whose query can come out slower than brute force.
#' Fewer `bits_per_hash` widens the buckets, more `num_tables` trades memory
#' for recall. No Manhattan.
#'
#' @references Lv et al., VLDB, 2007
#'
#' @examples
#' x <- generate_clustered_data(1000L, 16L)$data
#' idx <- LshIndex$new(x)
#' res <- idx$predict(x[1:5, ], k = 10L)
#'
#' @export
LshIndex <- R6::R6Class(
  "LshIndex",
  inherit = AnnIndex,
  public = list(
    #' @description
    #' Build the index.
    #'
    #' @param data Numeric matrix or data.frame. Samples x features. An index
    #' pointer is also accepted; [load_ann_index()] uses that path.
    #' @param metric String. One of `c("euclidean", "sqeuclidean", "cosine")`.
    #' @param num_tables Integer. Independent hash tables.
    #' @param bits_per_hash Integer. Total bits in a bucket code.
    #' @param slot_bits Integer or `NULL`. Bits each quantised projection
    #' contributes. `NULL` uses 1 for cosine and 2 otherwise.
    #' @param n_probe Integer or `NULL`. Buckets probed per table. `NULL` uses
    #' one per projection. Can be changed after the build.
    #' @param max_candidates Integer or `NULL`. Cap on candidates scored per
    #' query. `NULL` means no cap. Can be changed after the build.
    #' @param seed Integer. Fixes the random projections.
    #' @param precision String. `"float"` stores the data as f32, `"double"`
    #' as f64.
    initialize = function(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      num_tables = 8L,
      bits_per_hash = 12L,
      slot_bits = NULL,
      n_probe = NULL,
      max_candidates = NULL,
      seed = 42L,
      precision = c("float", "double")
    ) {
      metric <- match.arg(metric)
      precision <- match.arg(precision)
      private$algo <- "lsh"
      private$set_metric(metric, c("euclidean", "sqeuclidean", "cosine"))
      checkmate::qassert(num_tables, "X1[1,)")
      checkmate::qassert(bits_per_hash, "X1[1,)")
      slot_bits <- .as_knob(slot_bits, .var.name = "slot_bits")
      checkmate::qassert(seed, "X1[0,)")
      checkmate::assertChoice(precision, c("float", "double"))

      ptr <- if (.is_ptr(data)) {
        data
      } else {
        rs_lsh_build(
          .as_ann_matrix(data),
          private$core_metric,
          as.integer(num_tables),
          as.integer(bits_per_hash),
          slot_bits,
          as.integer(seed),
          precision
        )
      }
      private$attach(ptr)
      self$n_probe <- n_probe
      self$max_candidates <- max_candidates
    }
  ),
  active = list(
    #' @field n_probe Integer or `NULL`. Buckets probed per table.
    n_probe = function(value) {
      if (missing(value)) {
        return(private$.n_probe)
      }
      private$.n_probe <- .as_knob(value, .var.name = "n_probe")
    },
    #' @field max_candidates Integer or `NULL`. Cap on candidates scored.
    max_candidates = function(value) {
      if (missing(value)) {
        return(private$.max_candidates)
      }
      private$.max_candidates <- .as_knob(value, .var.name = "max_candidates")
    }
  ),
  private = list(
    .n_probe = NULL,
    .max_candidates = NULL,
    knobs = function() {
      list(n_probe = private$.n_probe, max_candidates = private$.max_candidates)
    },
    query = function(newdata, k, return_dist, verbose) {
      rs_lsh_query(
        private$ptr,
        newdata,
        k,
        private$.n_probe,
        private$.max_candidates,
        private$sqrt,
        return_dist,
        verbose
      )
    },
    query_self_impl = function(k, return_dist, verbose) {
      rs_lsh_self(
        private$ptr,
        k,
        private$.n_probe,
        private$.max_candidates,
        private$sqrt,
        return_dist,
        verbose
      )
    }
  )
)
