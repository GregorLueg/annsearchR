# Query an index

S3 wrapper around the `$predict()` method of an
[AnnIndex](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md).

## Usage

``` r
# S3 method for class 'AnnIndex'
predict(object, newdata, k = 15L, ...)
```

## Arguments

- object:

  An
  [AnnIndex](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md).

- newdata:

  Numeric matrix or data.frame. Queries x features.

- k:

  Integer. Number of neighbours.

- ...:

  Passed on to `$predict()`: `return_dist`, `.verbose`.

## Value

A list with `idx` and `dist`. See
[AnnIndex](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md).
