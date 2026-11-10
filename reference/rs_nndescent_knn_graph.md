# Build the NN-Descent kNN graph without an index

**\[experimental\]** Use
[`knn_graph_nndescent()`](https://gregorlueg.github.io/annsearchR/reference/knn_graph_nndescent.md)
instead.

## Usage

``` r
rs_nndescent_knn_graph(
  data,
  metric,
  k_graph,
  delta,
  max_iter,
  max_candidates,
  n_trees,
  include_self,
  sqrt,
  return_dist,
  seed,
  precision,
  verbose
)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine", "manhattan")`.

- k_graph:

  Integer. Neighbours per node found by the descent, the sample itself
  not counted.

- delta:

  Numeric. Convergence threshold.

- max_iter:

  Integer or `NULL`. Iteration cap.

- max_candidates:

  Integer or `NULL`. Candidates sampled per local join.

- n_trees:

  Integer or `NULL`. Random projection trees for the seed graph.

- include_self:

  Boolean. Prepend each point at distance 0.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Integer. 0 silent, 1 progress, 2 detailed.

## Value

A list with `idx` (1-based integer matrix, `k_graph` columns plus one
with `include_self`) and `dist` (double matrix or `NULL`).
