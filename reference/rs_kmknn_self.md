# Self-query a kMkNN index

**\[experimental\]** Use the `$query_self()` method instead.

## Usage

``` r
rs_kmknn_self(ptr, k, sqrt, return_dist, verbose)
```

## Arguments

- ptr:

  External pointer to the index.

- k:

  Integer. Number of neighbours, including the point itself.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

- verbose:

  Boolean. Print progress.

## Value

A list with `idx` (1-based integer matrix) and `dist` (double matrix or
`NULL`).
