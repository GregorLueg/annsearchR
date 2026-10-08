# shared data ------------------------------------------------------------------

dat <- generate_clustered_data(2000L, 16L, n_clusters = 10L, seed = 1L)$data
q <- generate_clustered_data(100L, 16L, n_clusters = 10L, seed = 2L)$data
k <- 10L

truth <- ExhaustiveIndex$new(dat)$predict(q, k = k)$idx
truth_cos <- ExhaustiveIndex$new(dat, metric = "cosine")$predict(q, k = k)$idx

# recall helper ----------------------------------------------------------------

expect_equal(knn_recall(truth, truth), 1)
expect_equal(knn_recall(truth, truth[, k:1]), 1)
expect_equal(knn_recall(truth, truth, k = 5L), 1)
na_mat <- truth
na_mat[] <- NA_integer_
expect_equal(knn_recall(truth, na_mat), 0)

# hnsw -------------------------------------------------------------------------

hnsw <- HnswIndex$new(dat)
expect_true(knn_recall(truth, hnsw$predict(q, k = k)$idx) > 0.9)
expect_true(
  knn_recall(
    truth_cos,
    HnswIndex$new(dat, metric = "cosine")$predict(q, k = k)$idx
  ) >
    0.9
)

s <- hnsw$query_self(k = k)
expect_equal(s$idx[, 1], seq_len(2000))

hnsw$ef_search <- 200L
expect_equal(hnsw$ef_search, 200L)
expect_error(hnsw$ef_search <- 0L)

# same seed, same graph; the parallel build is only bit-identical on 1 thread
ann_set_threads(1L)
expect_equal(
  HnswIndex$new(dat, seed = 7L)$predict(q, k = k),
  HnswIndex$new(dat, seed = 7L)$predict(q, k = k)
)
ann_set_threads(0L)

# f64 agrees with f32 on the neighbours
expect_true(
  knn_recall(
    truth,
    HnswIndex$new(dat, precision = "double")$predict(q, k = k)$idx
  ) >
    0.9
)
expect_equal(HnswIndex$new(dat, precision = "double")$precision, "double")

# annoy ------------------------------------------------------------------------

annoy <- AnnoyIndex$new(dat)
expect_true(knn_recall(truth, annoy$predict(q, k = k)$idx) > 0.9)
expect_null(annoy$search_budget)
annoy$search_budget <- 5000L
expect_equal(annoy$search_budget, 5000L)
annoy$search_budget <- NULL
expect_null(annoy$search_budget)

expect_error(AnnoyIndex$new(dat, metric = "manhattan"))

# threads ----------------------------------------------------------------------

old <- ann_set_threads(2L)
expect_equal(ann_get_threads(), 2L)
expect_equal(hnsw$predict(q, k = k), hnsw$predict(q, k = k))
ann_set_threads(0L)
