#' Index classes by algorithm name
#'
#' @returns Named list of R6 generators, keyed by the algorithm name the Rust
#' side reports.
#'
#' @keywords internal
.ann_classes <- function() {
  list(
    exhaustive = ExhaustiveIndex,
    annoy = AnnoyIndex,
    hnsw = HnswIndex
  )
}

#' Load an index written by `$save()`
#'
#' @description
#' Reads the index bundle and its R-side parameters (metric, search knobs)
#' back into the matching [AnnIndex] subclass. The float width is read from the
#' bundle. Bundles are tied to the on-disk format version of the underlying
#' Rust crate; a format bump means rebuilding.
#'
#' @param dir String. Directory written by `$save()`.
#'
#' @returns An [AnnIndex] subclass, ready to query.
#'
#' @export
load_ann_index <- function(dir) {
  checkmate::assertDirectoryExists(dir)
  params_file <- file.path(dir, "params.rds")
  checkmate::assertFileExists(params_file)

  params <- readRDS(params_file)
  cls <- .ann_classes()[[params$algo]]
  if (is.null(cls)) {
    stop(sprintf("Unknown index type '%s' in %s.", params$algo, params_file))
  }

  ptr <- rs_ann_load(dir, params$algo)
  do.call(cls$new, c(list(data = ptr, metric = params$metric), params$knobs))
}
