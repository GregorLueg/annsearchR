# Query a relative NN-Descent index

**\[experimental\]** Use the `$predict()` method instead.

## Usage

``` r
rs_rnndescent_query(
  ptr,
  data,
  k,
  ef_search,
  k_search,
  sqrt,
  return_dist,
  verbose
)
```

## Arguments

- ptr:

  External pointer to the index.

- data:

  Numeric matrix. Queries x features.

- k:

  Integer. Number of neighbours.

- ef_search:

  Integer or `NULL`. Beam width at query time.

- k_search:

  Integer or `NULL`. Neighbours expanded per hop.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

- verbose:

  Boolean. Print progress.

## Value

A list with `idx` (1-based integer matrix) and `dist` (double matrix or
`NULL`).
