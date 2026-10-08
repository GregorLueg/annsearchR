# Query an LSH index

**\[experimental\]** Use the `$predict()` method instead.

## Usage

``` r
rs_lsh_query(ptr, data, k, n_probe, max_candidates, sqrt, return_dist, verbose)
```

## Arguments

- ptr:

  External pointer to the index.

- data:

  Numeric matrix. Queries x features.

- k:

  Integer. Number of neighbours.

- n_probe:

  Integer or `NULL`. Buckets probed per table. `NULL` means one per
  projection.

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
