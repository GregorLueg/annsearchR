# helpers ----------------------------------------------------------------------

#' Metric names and how they map onto the Rust core
#'
#' @description
#' The core works in squared Euclidean, so `"euclidean"` carries a flag to
#' square root the distances on the way out. The core also silently falls back
#' to squared Euclidean on a string it does not know, which is why every metric
#' is validated here before it gets anywhere near Rust.
#'
#' @returns A named list. Each element has `core` (string passed to Rust) and
#' `sqrt` (boolean).
#'
#' @keywords internal
.ann_metrics <- function() {
  list(
    euclidean = list(core = "euclidean", sqrt = TRUE),
    sqeuclidean = list(core = "euclidean", sqrt = FALSE),
    cosine = list(core = "cosine", sqrt = FALSE),
    manhattan = list(core = "manhattan", sqrt = FALSE)
  )
}

#' Coerce and validate a data matrix for the Rust side
#'
#' @param x Numeric matrix or data.frame of numeric columns. Samples x
#' features. No missing values.
#' @param dim Optional integer. Required number of columns.
#' @param .var.name String. Name used in error messages.
#'
#' @returns A double matrix.
#'
#' @keywords internal
.as_ann_matrix <- function(x, dim = NULL, .var.name = "data") {
  if (is.data.frame(x)) {
    x <- as.matrix(x)
  }
  checkmate::assertMatrix(
    x,
    mode = "numeric",
    any.missing = FALSE,
    min.rows = 1L,
    min.cols = 1L,
    .var.name = .var.name
  )
  if (!is.null(dim) && ncol(x) != dim) {
    stop(sprintf(
      "`%s` has %d columns, the index was built with %d.",
      .var.name,
      ncol(x),
      dim
    ))
  }
  if (!is.double(x)) {
    storage.mode(x) <- "double"
  }
  if (any(!is.finite(x))) {
    stop(sprintf("`%s` contains non-finite values.", .var.name))
  }
  x
}

#' Validate a search-time knob
#'
#' @param value Positive integer, or `NULL` if `null_ok`.
#' @param null_ok Boolean. Whether `NULL` (let the crate pick) is allowed.
#' @param .var.name String. Name used in error messages.
#'
#' @returns `value` as integer, or `NULL`.
#'
#' @keywords internal
.as_knob <- function(value, null_ok = TRUE, .var.name = "value") {
  checkmate::qassert(
    value,
    if (null_ok) c("0", "X1[1,)") else "X1[1,)",
    .var.name = .var.name
  )
  if (is.null(value)) NULL else as.integer(value)
}

#' Is this an external pointer, alive or dead
#'
#' @param x Any R object.
#'
#' @returns Boolean.
#'
#' @keywords internal
.is_ptr <- function(x) {
  typeof(x) == "externalptr"
}

# AnnIndex ---------------------------------------------------------------------

#' Base class for all nearest neighbour indices
#'
#' @description
#' Holds a pointer to an index living in Rust memory, plus the bits R needs to
#' talk to it (metric, precision, shape). Never instantiated directly: use one
#' of the algorithm classes such as [HnswIndex], [AnnoyIndex] or
#' [ExhaustiveIndex].
#'
#' The index itself is not serialised by [saveRDS()]. A restored object holds
#' a dead pointer and every method errors. Use `$save()` and
#' [load_ann_index()] instead.
#'
#' @export
AnnIndex <- R6::R6Class(
  "AnnIndex",
  public = list(
    #' @description
    #' Find the `k` nearest indexed samples for each row of `newdata`.
    #'
    #' @param newdata Numeric matrix or data.frame. Queries x features, same
    #' number of features as the index.
    #' @param k Integer. Number of neighbours.
    #' @param return_dist Boolean. Return the distances as well.
    #' @param .verbose Boolean. Print progress from Rust.
    #'
    #' @returns A list with:
    #' \itemize{
    #'   \item idx - Integer matrix, queries x k. 1-based row indices into the
    #'   indexed data. `NA` where fewer than `k` neighbours were found.
    #'   \item dist - Numeric matrix, queries x k, or `NULL` if
    #'   `return_dist = FALSE`. `Inf` where `idx` is `NA`.
    #' }
    predict = function(newdata, k = 15L, return_dist = TRUE, .verbose = FALSE) {
      private$check_ptr()
      newdata <- .as_ann_matrix(newdata, private$.dim, .var.name = "newdata")
      checkmate::qassert(k, "X1[1,)")
      checkmate::qassert(return_dist, "B1")
      checkmate::qassert(.verbose, "B1")

      private$query(newdata, as.integer(k), return_dist, .verbose)
    },

    #' @description
    #' kNN graph over the indexed data itself. Uses each index's own self-query
    #' path, which is faster than `$predict()` on the training data.
    #'
    #' @param k Integer. Number of neighbours, including the sample itself.
    #' @param return_dist Boolean. Return the distances as well.
    #' @param .verbose Boolean. Print progress from Rust.
    #'
    #' @returns A list with `idx` and `dist`, as for `$predict()`, with one row
    #' per indexed sample.
    query_self = function(k = 15L, return_dist = TRUE, .verbose = FALSE) {
      private$check_ptr()
      checkmate::qassert(k, "X1[1,)")
      checkmate::qassert(return_dist, "B1")
      checkmate::qassert(.verbose, "B1")

      private$query_self_impl(as.integer(k), return_dist, .verbose)
    },

    #' @description
    #' Write the index to a directory. Read it back with [load_ann_index()].
    #'
    #' @param dir String. Target directory, created if missing.
    #'
    #' @returns The object, invisibly.
    save = function(dir) {
      private$check_ptr()
      checkmate::qassert(dir, "S1")
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      rs_ann_save(private$ptr, dir)
      saveRDS(
        list(
          algo = private$algo,
          metric = private$.metric,
          knobs = private$knobs()
        ),
        file.path(dir, "params.rds")
      )
      invisible(self)
    },

    #' @description
    #' Print a one-line summary.
    #'
    #' @param ... Ignored.
    #'
    #' @returns The object, invisibly.
    print = function(...) {
      knobs <- private$knobs()
      knob_str <- if (length(knobs)) {
        paste0(
          " | ",
          paste(
            names(knobs),
            vapply(
              knobs,
              \(x) if (is.null(x)) "auto" else format(x),
              character(1)
            ),
            sep = " = ",
            collapse = ", "
          )
        )
      } else {
        ""
      }
      alive <- !identical(private$ptr, methods::new("externalptr"))
      cat(sprintf(
        "<%s> %d x %d | metric: %s | precision: %s%s%s\n",
        class(self)[1],
        private$.n,
        private$.dim,
        private$.metric,
        private$.precision,
        knob_str,
        if (alive) "" else " | DEAD POINTER"
      ))
      invisible(self)
    }
  ),
  active = list(
    #' @field n Integer. Number of indexed samples. Read-only.
    n = function(value) {
      if (!missing(value)) stop("`n` is read-only.")
      private$.n
    },
    #' @field dim Integer. Number of features. Read-only.
    dim = function(value) {
      if (!missing(value)) stop("`dim` is read-only.")
      private$.dim
    },
    #' @field metric String. Distance metric. Read-only.
    metric = function(value) {
      if (!missing(value)) stop("`metric` is read-only.")
      private$.metric
    },
    #' @field precision String. `"float"` or `"double"`. Read-only.
    precision = function(value) {
      if (!missing(value)) stop("`precision` is read-only.")
      private$.precision
    }
  ),
  private = list(
    ptr = NULL,
    algo = NULL,
    .metric = NULL,
    core_metric = NULL,
    sqrt = FALSE,
    .precision = NULL,
    .n = NULL,
    .dim = NULL,

    # Validate the metric against what this index supports and resolve it for
    # the core. Must run before any build.
    set_metric = function(metric, supported) {
      checkmate::assertChoice(metric, supported)
      spec <- .ann_metrics()[[metric]]
      private$.metric <- metric
      private$core_metric <- spec$core
      private$sqrt <- spec$sqrt
    },

    # Take ownership of a pointer and read its shape and precision back from
    # Rust, so a loaded index and a freshly built one end up identical.
    attach = function(ptr) {
      info <- rs_ann_info(ptr)
      if (info$algo != private$algo) {
        stop(sprintf(
          "Pointer holds a '%s' index, expected '%s'.",
          info$algo,
          private$algo
        ))
      }
      private$ptr <- ptr
      private$.precision <- info$precision
      private$.n <- info$n
      private$.dim <- info$dim
    },

    check_ptr = function() {
      if (identical(private$ptr, methods::new("externalptr"))) {
        stop(
          "The index pointer is dead, most likely because the object went ",
          "through saveRDS()/readRDS(). Use `$save()` and `load_ann_index()`."
        )
      }
    },

    # Search-time knobs, as a named list. Saved alongside the index.
    knobs = function() list(),

    query = function(newdata, k, return_dist, verbose) {
      stop("Not implemented for the base class.")
    },

    query_self_impl = function(k, return_dist, verbose) {
      stop("Not implemented for the base class.")
    }
  )
)

#' Query an index
#'
#' @description
#' S3 wrapper around the `$predict()` method of an [AnnIndex].
#'
#' @param object An [AnnIndex].
#' @param newdata Numeric matrix or data.frame. Queries x features.
#' @param k Integer. Number of neighbours.
#' @param ... Passed on to `$predict()`: `return_dist`, `.verbose`.
#'
#' @returns A list with `idx` and `dist`. See [AnnIndex].
#'
#' @export
predict.AnnIndex <- function(object, newdata, k = 15L, ...) {
  checkmate::assertR6(object, "AnnIndex")
  object$predict(newdata, k = k, ...)
}
