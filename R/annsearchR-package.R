#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom lifecycle deprecated
#' @importFrom stats predict
#' @importFrom R6 R6Class
#' @importFrom methods new
## usethis namespace: end
NULL

#' Cap the thread pool under R CMD check --as-cran
#'
#' @description
#' CRAN flags examples and tests whose CPU time exceeds 2.5x elapsed, and the
#' default Rayon pool takes every core. `_R_CHECK_LIMIT_CORES_` is set by
#' `--as-cran`, so two threads it is.
#'
#' @param libname,pkgname Passed by R, unused.
#'
#' @noRd
.onLoad <- function(libname, pkgname) {
  limit <- tolower(Sys.getenv("_R_CHECK_LIMIT_CORES_"))
  if (nzchar(limit) && limit != "false") {
    rs_set_threads(2L)
  }
}
