# Build a SOAR index

**\[experimental\]** Use
[SoarIndex](https://gregorlueg.github.io/annsearchR/reference/SoarIndex.md)
instead.

## Usage

``` r
rs_soar_build(
  data,
  metric,
  nlist,
  rule,
  rule_param,
  kmeans_iters,
  kmeans_balanced,
  seed,
  precision,
  verbose
)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine")`.

- nlist:

  Integer or `NULL`. Number of Voronoi cells.

- rule:

  String or `NULL`. Spilling rule.

- rule_param:

  Numeric or `NULL`. `mu` (shifted) or `lambda` (orthogonal).

- kmeans_iters:

  Integer or `NULL`. Lloyd iterations.

- kmeans_balanced:

  Boolean. Reseed starved centroids.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Boolean. Print progress.

## Value

External pointer to the index.
