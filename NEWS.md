# annsearchR 0.2.0

- Built on ann-search-rs 0.12.2.
- Smaller indices in memory and on disk. Stored point ids are 32-bit
  throughout, the Annoy, kd and ball tree forests build in place over one
  permutation per tree, and NN-Descent no longer keeps a second, reordered
  copy of the vectors. NSG builds its internal kNN graph without the
  NN-Descent search structure. On SIFT-128 (1M x 128, 10 threads), the
  NN-Descent build peaks at 6.3 GB instead of 8.2 GB and saves to 1.9 GB
  instead of 2.4 GB; Annoy peaks at 5.2 GB instead of 6.0 GB and builds in
  7.0 s instead of 8.3 s; the kd forest peaks at 3.7 GB instead of 4.2 GB.
  Recall is unchanged and query speed is within run-to-run noise.
- New `knn_graph_nndescent()`: matrix in, kNN graph out, no index kept. Same
  graph as `NNDescentIndex$new()` followed by `$extract_knn()` at the same
  seed and `n_trees`. On SIFT-128 (1M x 128, 10 threads, `k_graph = 15`) it
  peaks at 5.0 GB instead of 6.0 GB, at the same build time (14.7 s).
- `NNDescentIndex$extract_knn()` reads the full kNN graph whatever
  `diversify_prob` is set to; the docs said otherwise.
- Manhattan NN-Descent seeds its graph by kd-tree leaf join, like the other
  metrics.
- `.verbose` takes `0`, `1` or `2` as well as `FALSE`/`TRUE`. `2` prints timed
  build stages. Every constructor has `.verbose` now, including
  `ExhaustiveIndex`, `AnnoyIndex`, `KdTreeIndex`, `BallTreeIndex`, `LshIndex`
  and `VamanaIndex`.
- Datasets with more than `2^32 - 2` samples (`2^31 - 2` for NN-Descent and
  RNN-Descent) are refused with an error.
- Breaking: the on-disk format changed. Indices saved with 0.1.0 do not load,
  rebuild and save them again.
- `faer` comes in without its `npy` feature, which drops nine crates from the
  vendored Rust sources.
- The benchmarks article is rerun on 0.2.0.

# annsearchR 0.1.0

First CRAN release.

- Thirteen CPU indices behind one R6 interface: brute force, kMkNN, Annoy, k-d
  forest, ball tree, IVF, SOAR, LSH, HNSW, NN-Descent, Vamana, NSG and
  RNN-Descent. Euclidean, squared Euclidean, cosine and Manhattan distances,
  f32 or f64 storage, save to disk and load back.
- Built on ann-search-rs 0.11.0. NN-Descent now seeds its graph by joining
  every forest leaf, as PyNNDescent does, and the default `n_trees` moved to
  scanpy's `min(5 + round(sqrt(n) / 20), 64)`. Expect different graphs at the
  same seed than with the r-universe 0.0.1 builds.
- Under `R CMD check --as-cran` the thread pool starts at two threads. Outside
  of a check it still takes every core, see `ann_set_threads()`.
- The Rust crates ship vendored in `src/rust/vendor.tar.xz` and compile offline.
