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
