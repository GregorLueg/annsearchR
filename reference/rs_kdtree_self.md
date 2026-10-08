# Self-query a kd forest index

**\[experimental\]** Use the `$query_self()` method instead.

## Usage

``` r
rs_kdtree_self(ptr, k, search_budget, sqrt, return_dist, verbose)
```

## Arguments

- ptr:

  External pointer to the index.

- k:

  Integer. Number of neighbours, including the point itself.

- search_budget:

  Integer or `NULL`. Candidates inspected per query.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

- verbose:

  Boolean. Print progress.

## Value

A list with `idx` (1-based integer matrix) and `dist` (double matrix or
`NULL`).
