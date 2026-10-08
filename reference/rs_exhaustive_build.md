# Build an exhaustive index

**\[experimental\]** Use
[ExhaustiveIndex](https://gregorlueg.github.io/annsearchR/reference/ExhaustiveIndex.md)
instead.

## Usage

``` r
rs_exhaustive_build(data, metric, precision)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine", "manhattan")`.

- precision:

  String. `"float"` or `"double"`.

## Value

External pointer to the index.
