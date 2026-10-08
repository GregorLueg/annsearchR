# save / load round trip -------------------------------------------------------

dat <- generate_clustered_data(500L, 8L, n_clusters = 5L)$data
q <- dat[1:20, ]

indices <- list(
  ExhaustiveIndex$new(dat, metric = "cosine"),
  AnnoyIndex$new(dat, search_budget = 2000L, precision = "double"),
  HnswIndex$new(dat, ef_search = 80L)
)

for (idx in indices) {
  dir <- tempfile()
  idx$save(dir)
  loaded <- load_ann_index(dir)
  cls <- class(idx)[1]
  expect_true(inherits(loaded, cls), info = cls)
  expect_equal(loaded$metric, idx$metric, info = cls)
  expect_equal(loaded$precision, idx$precision, info = cls)
  expect_equal(loaded$n, idx$n, info = cls)
  expect_equal(
    loaded$predict(q, k = 5L),
    idx$predict(q, k = 5L),
    info = cls
  )
}

expect_error(load_ann_index(file.path(tempdir(), "nope_not_here")))

# dead pointer after serialisation ---------------------------------------------

hnsw <- HnswIndex$new(dat)
restored <- unserialize(serialize(hnsw, NULL))
expect_error(restored$predict(q, k = 5L), "load_ann_index")
expect_error(restored$query_self(k = 5L), "load_ann_index")
