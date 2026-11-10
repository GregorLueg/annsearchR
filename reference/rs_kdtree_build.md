# Build a kd forest index

**\[experimental\]** Use
[KdTreeIndex](https://gregorlueg.github.io/annsearchR/reference/KdTreeIndex.md)
instead.

## Usage

``` r
rs_kdtree_build(data, metric, n_trees, seed, precision, verbose)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine", "manhattan")`.

- n_trees:

  Integer. Number of trees.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Integer. 0 silent, 1 progress, 2 detailed.

## Value

External pointer to the index.
