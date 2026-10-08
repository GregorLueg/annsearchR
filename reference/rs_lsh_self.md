# Self-query an LSH index

**\[experimental\]** Use the `$query_self()` method instead.

## Usage

``` r
rs_lsh_self(ptr, k, n_probe, max_candidates, sqrt, return_dist, verbose)
```

## Arguments

- ptr:

  External pointer to the index.

- k:

  Integer. Number of neighbours, including the point itself.

- n_probe:

  Integer or `NULL`. Buckets probed per table.

- max_candidates:

  Integer or `NULL`. Cap on candidates scored.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

- verbose:

  Boolean. Print progress.

## Value

A list with `idx` (1-based integer matrix) and `dist` (double matrix or
`NULL`).
