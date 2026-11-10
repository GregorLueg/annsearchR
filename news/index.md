# Changelog

## annsearchR 0.2.0

- Breaking: new on-disk format. Indices saved with 0.1.0 need
  rebuilding.
- Built on ann-search-rs 0.12.2. Smaller indices in memory and on disk,
  e.g. the NN-Descent build on SIFT-128 peaks at 6.3 GB instead of 8.2
  GB. Recall and query speed unchanged.
- New
  [`knn_graph_nndescent()`](https://gregorlueg.github.io/annsearchR/reference/knn_graph_nndescent.md):
  the NN-Descent kNN graph without keeping an index, same graph as
  `$extract_knn()` at lower peak memory.
- `.verbose` on every constructor, taking `0`, `1` or `2` as well as
  `FALSE`/`TRUE`.
- Manhattan NN-Descent seeds by kd-tree leaf join, like the other
  metrics.
- Datasets above the 32-bit id limit are refused with an error.

## annsearchR 0.1.0

First CRAN release.

- Thirteen CPU indices behind one R6 interface: brute force, kMkNN,
  Annoy, k-d forest, ball tree, IVF, SOAR, LSH, HNSW, NN-Descent,
  Vamana, NSG and RNN-Descent. Euclidean, squared Euclidean, cosine and
  Manhattan distances, f32 or f64 storage, save to disk and load back.
- Built on ann-search-rs 0.11.0. NN-Descent now seeds its graph by
  joining every forest leaf, as PyNNDescent does, and the default
  `n_trees` moved to scanpy’s `min(5 + round(sqrt(n) / 20), 64)`. Expect
  different graphs at the same seed than with the r-universe 0.0.1
  builds.
- Under `R CMD check --as-cran` the thread pool starts at two threads.
  Outside of a check it still takes every core, see
  [`ann_set_threads()`](https://gregorlueg.github.io/annsearchR/reference/ann_set_threads.md).
- The Rust crates ship vendored in `src/rust/vendor.tar.xz` and compile
  offline.
