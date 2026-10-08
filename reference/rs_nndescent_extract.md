# Extract the converged NN-Descent graph

**\[experimental\]** Use the `$extract_knn()` method instead.

## Usage

``` r
rs_nndescent_extract(ptr, k, include_self, sqrt, return_dist)
```

## Arguments

- ptr:

  External pointer to the index.

- k:

  Integer. Row length, including the point itself when
  `include_self = TRUE`. At most the graph degree (plus one with self).

- include_self:

  Boolean. Prepend each point at distance 0.

- sqrt:

  Boolean. Square root the distances (true Euclidean).

- return_dist:

  Boolean. Return the distances.

## Value

A list with `idx` (1-based integer matrix) and `dist` (double matrix or
`NULL`).
