# exhaustive vs brute force in R -----------------------------------------------

set.seed(1)
x <- matrix(rnorm(200 * 8), 200)
q <- matrix(rnorm(10 * 8), 10)
k <- 5L

brute_force <- function(q, x, metric, k) {
  d <- switch(
    metric,
    euclidean = sqrt(pmax(
      outer(rowSums(q^2), rowSums(x^2), "+") - 2 * q %*% t(x),
      0
    )),
    sqeuclidean = outer(rowSums(q^2), rowSums(x^2), "+") - 2 * q %*% t(x),
    manhattan = t(apply(q, 1, \(r) colSums(abs(t(x) - r)))),
    cosine = 1 - (q / sqrt(rowSums(q^2))) %*% t(x / sqrt(rowSums(x^2)))
  )
  list(
    idx = t(apply(d, 1, order))[, seq_len(k)],
    dist = t(apply(d, 1, sort))[, seq_len(k)]
  )
}

for (metric in c("euclidean", "sqeuclidean", "cosine", "manhattan")) {
  truth <- brute_force(q, x, metric, k)
  for (precision in c("float", "double")) {
    tol <- if (precision == "float") 1e-5 else 1e-10
    res <- ExhaustiveIndex$new(x, metric = metric, precision = precision)$predict(
      q,
      k = k
    )
    expect_equal(
      res$idx,
      truth$idx,
      info = sprintf("idx: %s / %s", metric, precision)
    )
    expect_equal(
      res$dist,
      truth$dist,
      tolerance = tol,
      info = sprintf("dist: %s / %s", metric, precision)
    )
  }
}

# self query -------------------------------------------------------------------

idx <- ExhaustiveIndex$new(x)
s <- idx$query_self(k = k)
expect_equal(dim(s$idx), c(200L, k))
expect_equal(s$idx[, 1], seq_len(200))
expect_true(all(s$dist[, 1] == 0))

# output shape and padding -----------------------------------------------------

res <- idx$predict(q, k = 250L)
expect_true(is.integer(res$idx))
expect_equal(sum(is.na(res$idx)), 10L * 50L)
expect_true(all(is.infinite(res$dist[is.na(res$idx)])))

expect_null(idx$predict(q, k = k, return_dist = FALSE)$dist)
expect_equal(predict(idx, q, k = k), idx$predict(q, k = k))

# data.frame and integer input -------------------------------------------------

xi <- matrix(sample(1:10, 200 * 8, replace = TRUE), 200)
expect_silent(ExhaustiveIndex$new(as.data.frame(xi)))

# input validation -------------------------------------------------------------

expect_error(idx$predict(q[, 1:4], k = k), "columns")
q_na <- q
q_na[1, 1] <- NA
expect_error(idx$predict(q_na, k = k))
expect_error(idx$predict(q, k = 0L))
expect_error(ExhaustiveIndex$new(x, metric = "hamming"))
expect_error(idx$n <- 5L, "read-only")
