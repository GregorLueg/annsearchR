# Generate low-rank synthetic data

Cell types on an `intrinsic_dim`-dimensional manifold, isometrically
embedded in `dim` ambient dimensions with a touch of noise. Types are
grouped into lineages, with curved differentiation trajectories running
between types of the same lineage.

## Usage

``` r
generate_low_rank_data(
  n,
  dim,
  n_clusters = 25L,
  intrinsic_dim = 16L,
  seed = 42L
)
```

## Arguments

- n:

  Integer. Number of samples.

- dim:

  Integer. Number of features.

- n_clusters:

  Integer. Number of clusters.

- intrinsic_dim:

  Integer. True dimensionality of the manifold. Must not exceed `dim`.

- seed:

  Integer. Random seed.

## Value

A list with:

- data - Numeric matrix, n x dim.

- labels - Integer vector of 1-based cluster labels.

## Examples

``` r
dat <- generate_low_rank_data(1000L, 64L, intrinsic_dim = 8L)
```
