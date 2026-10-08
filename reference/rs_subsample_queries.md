# Subsample queries with noise

**\[experimental\]** Draws rows from `x` and adds light Gaussian noise.
Use
[`subsample_queries()`](https://gregorlueg.github.io/annsearchR/reference/subsample_queries.md)
instead.

## Usage

``` r
rs_subsample_queries(x, n, seed)
```

## Arguments

- x:

  Numeric matrix, samples x features. Cast to f32.

- n:

  Integer. Rows to draw, capped at `nrow(x)`.

- seed:

  Integer. Random seed.

## Value

A numeric matrix with `min(n, nrow(x))` rows.
