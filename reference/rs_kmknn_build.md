# Build a kMkNN index

**\[experimental\]** Use
[KmknnIndex](https://gregorlueg.github.io/annsearchR/reference/KmknnIndex.md)
instead.

## Usage

``` r
rs_kmknn_build(
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

  Integer or `NULL`. Number of k-means clusters.

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
