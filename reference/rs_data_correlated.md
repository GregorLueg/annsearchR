# Generate correlated synthetic data

**\[experimental\]** Clusters with local anisotropy plus a globally
shared off-axis subspace. Use
[`generate_correlated_data()`](https://gregorlueg.github.io/annsearchR/reference/generate_correlated_data.md)
instead.

## Usage

``` r
rs_data_correlated(n, dim, n_clusters, cor_strength, seed)
```

## Arguments

- n:

  Integer. Number of samples.

- dim:

  Integer. Number of features.

- n_clusters:

  Integer. Number of clusters.

- cor_strength:

  Numeric. Share of structured variance in the shared off-axis subspace,
  0 to 1.

- seed:

  Integer. Random seed.

## Value

A list with `data` (n x dim numeric matrix) and `labels` (1-based
integer cluster labels).
