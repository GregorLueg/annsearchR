# Build a ball tree index

**\[experimental\]** Use
[BallTreeIndex](https://gregorlueg.github.io/annsearchR/reference/BallTreeIndex.md)
instead.

## Usage

``` r
rs_balltree_build(data, metric, seed, precision, verbose)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine")`.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Integer. 0 silent, 1 progress, 2 detailed.

## Value

External pointer to the index.
