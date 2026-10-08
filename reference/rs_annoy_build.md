# Build an Annoy index

**\[experimental\]** Use
[AnnoyIndex](https://gregorlueg.github.io/annsearchR/reference/AnnoyIndex.md)
instead.

## Usage

``` r
rs_annoy_build(data, metric, n_trees, seed, precision)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine")`.

- n_trees:

  Integer. Number of trees.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

## Value

External pointer to the index.
