# Query an exhaustive index

**\[experimental\]** Use the `$predict()` method instead.

## Usage

``` r
rs_exhaustive_query(ptr, data, k, sqrt, return_dist, verbose)
```

## Arguments

- ptr:

  External pointer to the index.

- data:

  Numeric matrix. Queries x features.

- k:

  Integer. Number of neighbours.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

- verbose:

  Boolean. Print progress.

## Value

A list with `idx` (1-based integer matrix) and `dist` (double matrix or
`NULL`).
