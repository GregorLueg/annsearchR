# Build a ball tree index

**\[experimental\]** Use
[BallTreeIndex](https://gregorlueg.github.io/annsearchR/reference/BallTreeIndex.md)
instead.

## Usage

``` r
rs_balltree_build(data, metric, seed, precision)
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

## Value

External pointer to the index.
