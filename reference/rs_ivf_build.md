# Build an IVF index

**\[experimental\]** Use
[IvfIndex](https://gregorlueg.github.io/annsearchR/reference/IvfIndex.md)
instead.

## Usage

``` r
rs_ivf_build(
  data,
  metric,
  nlist,
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

- kmeans_iters:

  Integer or `NULL`. `NULL` uses e-means, an integer Lloyd's with that
  many iterations.

- kmeans_balanced:

  Boolean. Reseed starved centroids. Only affects Lloyd's
  (`kmeans_iters` set), ignored under e-means.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Integer. 0 silent, 1 progress, 2 detailed.

## Value

External pointer to the index.
