# Build a relative NN-Descent index

**\[experimental\]** Use
[RnnDescentIndex](https://gregorlueg.github.io/annsearchR/reference/RnnDescentIndex.md)
instead.

## Usage

``` r
rs_rnndescent_build(
  data,
  metric,
  s,
  r,
  t1,
  t2,
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

- s:

  Integer. Neighbours sampled per node per local join.

- r:

  Integer. Maximum out-degree after pruning.

- t1:

  Integer. Outer iterations.

- t2:

  Integer. Inner iterations per outer one.

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
