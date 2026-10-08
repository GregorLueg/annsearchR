# Generate clustered synthetic data

**\[experimental\]** Separated Gaussian clusters joined by inter-cluster
bridges. Use
[`generate_clustered_data()`](https://gregorlueg.github.io/annsearchR/reference/generate_clustered_data.md)
instead.

## Usage

``` r
rs_data_clustered(n, dim, n_clusters, seed)
```

## Arguments

- n:

  Integer. Number of samples.

- dim:

  Integer. Number of features.

- n_clusters:

  Integer. Number of clusters.

- seed:

  Integer. Random seed.

## Value

A list with `data` (n x dim numeric matrix) and `labels` (1-based
integer cluster labels).
