# shared data ------------------------------------------------------------------

# queries are held-out rows, so they come from the same clusters as the data
all_data <- generate_clustered_data(2100L, 16L, n_clusters = 10L, seed = 1L)$data
set.seed(3L)
held_out <- sample(2100L, 100L)
dat <- all_data[-held_out, ]
q <- all_data[held_out, ]
k <- 10L

classes <- annsearchR:::.ann_classes()
no_manhattan <- c("kmknn", "annoy", "balltree", "ivf", "soar", "lsh")

# BallTree's default budget (5% of points) is approximate by design
build <- function(nm, metric) {
  idx <- classes[[nm]]$new(dat, metric = metric)
  if (nm == "balltree") {
    idx$search_budget <- 500L
  }
  idx
}

# recall helper ----------------------------------------------------------------

truth <- ExhaustiveIndex$new(dat)$predict(q, k = k)$idx
expect_equal(knn_recall(truth, truth), 1)
expect_equal(knn_recall(truth, truth[, k:1]), 1)
expect_equal(knn_recall(truth, truth, k = 5L), 1)
na_mat <- truth
na_mat[] <- NA_integer_
expect_equal(knn_recall(truth, na_mat), 0)

# recall of every index against exhaustive -------------------------------------

for (metric in c("euclidean", "cosine", "manhattan")) {
  truth <- ExhaustiveIndex$new(dat, metric = metric)$predict(q, k = k)$idx
  truth_self <- ExhaustiveIndex$new(dat, metric = metric)$query_self(k = k)$idx
  for (nm in setdiff(names(classes), "exhaustive")) {
    if (metric == "manhattan" && nm %in% no_manhattan) {
      expect_error(classes[[nm]]$new(dat, metric = metric), info = nm)
      next
    }
    idx <- build(nm, metric)
    info <- sprintf("%s / %s", nm, metric)
    res <- idx$predict(q, k = k)
    expect_equal(dim(res$idx), c(nrow(q), k), info = info)
    expect_true(knn_recall(truth, res$idx) > 0.9, info = info)
    expect_true(
      knn_recall(truth_self, idx$query_self(k = k)$idx) > 0.9,
      info = info
    )
  }
}

# search knobs -----------------------------------------------------------------

hnsw <- HnswIndex$new(dat)
hnsw$ef_search <- 200L
expect_equal(hnsw$ef_search, 200L)
expect_error(hnsw$ef_search <- 0L)
expect_error(hnsw$ef_search <- NULL)

annoy <- AnnoyIndex$new(dat)
expect_null(annoy$search_budget)
annoy$search_budget <- 5000L
expect_equal(annoy$search_budget, 5000L)
annoy$search_budget <- NULL
expect_null(annoy$search_budget)

ivf <- IvfIndex$new(dat, nlist = 20L)
ivf$nprobe <- 20L
truth <- ExhaustiveIndex$new(dat)$predict(q, k = k)$idx
expect_equal(knn_recall(truth, ivf$predict(q, k = k)$idx), 1)

lsh <- LshIndex$new(dat, max_candidates = 50L)
expect_equal(lsh$max_candidates, 50L)

expect_error(SoarIndex$new(dat, rule = "sideways"))
expect_silent(SoarIndex$new(dat, rule = "nearest"))

# nndescent graph extraction ---------------------------------------------------

nn <- NNDescentIndex$new(dat, k_graph = 15L)
expect_equal(nn$k_graph, 15L)
e <- nn$extract_knn()
expect_equal(dim(e$idx), c(nrow(dat), 15L))
expect_equal(e$idx[, 1], seq_len(nrow(dat)))
truth_self <- ExhaustiveIndex$new(dat)$query_self(k = 15L)$idx
expect_true(knn_recall(truth_self, e$idx) > 0.95)

e <- nn$extract_knn(k = 10L, include_self = FALSE, return_dist = FALSE)
expect_equal(dim(e$idx), c(nrow(dat), 10L))
expect_false(any(e$idx == seq_len(nrow(dat))))
expect_null(e$dist)

# reproducibility --------------------------------------------------------------

# the parallel HNSW build is only bit-identical on 1 thread
ann_set_threads(1L)
expect_equal(
  HnswIndex$new(dat, seed = 7L)$predict(q, k = k),
  HnswIndex$new(dat, seed = 7L)$predict(q, k = k)
)
ann_set_threads(0L)
expect_equal(
  AnnoyIndex$new(dat, seed = 7L)$predict(q, k = k),
  AnnoyIndex$new(dat, seed = 7L)$predict(q, k = k)
)

# precision --------------------------------------------------------------------

truth <- ExhaustiveIndex$new(dat)$predict(q, k = k)$idx
hnsw64 <- HnswIndex$new(dat, precision = "double")
expect_equal(hnsw64$precision, "double")
expect_true(knn_recall(truth, hnsw64$predict(q, k = k)$idx) > 0.9)

# threads ----------------------------------------------------------------------

old <- ann_set_threads(2L)
expect_equal(ann_get_threads(), 2L)
expect_equal(hnsw$predict(q, k = k), hnsw$predict(q, k = k))
ann_set_threads(0L)
