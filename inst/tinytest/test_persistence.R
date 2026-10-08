# save / load round trip for every index ---------------------------------------

dat <- generate_clustered_data(500L, 8L, n_clusters = 5L)$data
q <- dat[1:20, ]

classes <- annsearchR:::.ann_classes()

for (nm in names(classes)) {
  idx <- classes[[nm]]$new(dat, metric = "cosine", precision = "double")
  dir <- tempfile()
  idx$save(dir)
  loaded <- load_ann_index(dir)
  expect_true(inherits(loaded, class(idx)[1]), info = nm)
  expect_equal(loaded$metric, "cosine", info = nm)
  expect_equal(loaded$precision, "double", info = nm)
  expect_equal(loaded$n, idx$n, info = nm)
  expect_equal(loaded$predict(q, k = 5L), idx$predict(q, k = 5L), info = nm)
}

# search knobs survive the round trip
hnsw <- HnswIndex$new(dat, ef_search = 80L)
dir <- tempfile()
hnsw$save(dir)
expect_equal(load_ann_index(dir)$ef_search, 80L)

nn <- NNDescentIndex$new(dat, k_graph = 12L)
dir <- tempfile()
nn$save(dir)
expect_equal(load_ann_index(dir)$extract_knn(), nn$extract_knn())

expect_error(load_ann_index(file.path(tempdir(), "nope_not_here")))

# dead pointer after serialisation ---------------------------------------------

restored <- unserialize(serialize(hnsw, NULL))
expect_error(restored$predict(q, k = 5L), "load_ann_index")
expect_error(restored$query_self(k = 5L), "load_ann_index")
expect_error(restored$save(tempfile()), "load_ann_index")
