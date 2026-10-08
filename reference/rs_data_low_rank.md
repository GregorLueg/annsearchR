# Generate low-rank synthetic data

**\[experimental\]** Cell types on a low-dimensional manifold inside a
higher-dimensional space, with trajectories between them. Use
[`generate_low_rank_data()`](https://gregorlueg.github.io/annsearchR/reference/generate_low_rank_data.md)
instead.

## Usage

``` r
rs_data_low_rank(n, dim, intrinsic_dim, n_clusters, seed)
```

## Arguments

- n:

  Integer. Number of samples.

- dim:

  Integer. Ambient number of features.

- intrinsic_dim:

  Integer. Dimensionality of the manifold. Must not exceed `dim`; the
  crate panics otherwise.

- n_clusters:

  Integer. Number of cell types.

- seed:

  Integer. Random seed.

## Value

A list with `data` (n x dim numeric matrix) and `labels` (1-based
integer cluster labels).
