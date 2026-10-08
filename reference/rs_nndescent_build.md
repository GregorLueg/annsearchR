# Build an NN-Descent index

**\[experimental\]** Use
[NNDescentIndex](https://gregorlueg.github.io/annsearchR/reference/NNDescentIndex.md)
instead.

## Usage

``` r
rs_nndescent_build(
  data,
  metric,
  k_graph,
  delta,
  diversify_prob,
  max_iter,
  max_candidates,
  n_trees,
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

  Integer. Neighbours per node in the graph.

- delta:

  Numeric. Convergence threshold.

- diversify_prob:

  Numeric. Edge pruning probability after descent.

- max_iter:

  Integer or `NULL`. Iteration cap.

- max_candidates:

  Integer or `NULL`. Candidates sampled per local join.

- n_trees:

  Integer or `NULL`. Random projection trees for the seed graph.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Boolean. Print progress.

## Value

External pointer to the index.
