# Self-query an NSG index

**\[experimental\]** Use the `$query_self()` method instead.

## Usage

``` r
rs_nsg_self(ptr, k, ef_search, sqrt, return_dist, verbose)
```

## Arguments

- ptr:

  External pointer to the index.

- k:

  Integer. Number of neighbours, including the point itself.

- ef_search:

  Integer or `NULL`. Beam width at query time.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

- verbose:

  Boolean. Print progress.

## Value

A list with `idx` (1-based integer matrix) and `dist` (double matrix or
`NULL`).
