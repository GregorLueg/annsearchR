# Subsample queries from a dataset

Draws rows from `x` and adds light Gaussian noise (sd 0.05). Querying an
index with the rows it was built from flatters it: every query has an
exact hit at distance zero. This puts the queries near the data instead
of on it. The data is cast to f32 first, as in the Python bindings.

## Usage

``` r
subsample_queries(x, n, seed = 42L)
```

## Arguments

- x:

  Numeric matrix, samples x features.

- n:

  Integer. Number of rows to draw, capped at `nrow(x)`.

- seed:

  Integer. Random seed for the draw and the noise.

## Value

Numeric matrix with `min(n, nrow(x))` rows and `ncol(x)` columns.

## Examples

``` r
dat <- generate_clustered_data(1000L, 16L)$data
query <- subsample_queries(dat, 100L)
```
