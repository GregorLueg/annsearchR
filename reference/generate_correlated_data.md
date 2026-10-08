# Generate correlated synthetic data

Well-separated clusters, each an arbitrarily oriented ellipsoid, plus a
globally shared off-axis subspace that correlates the features. None of
the structured variance lines up with the coordinate axes, and bridges
between neighbouring clusters keep the blobs reachable for graph
indices.

## Usage

``` r
generate_correlated_data(
  n,
  dim,
  n_clusters = 25L,
  cor_strength = 0.5,
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

- cor_strength:

  Numeric. Share of the structured variance in the shared off-axis
  subspace, between 0 (all cluster-local) and 1 (all shared). 0.5 is the
  value behind the crate's benchmark tables.

- seed:

  Integer. Random seed.

## Value

A list with:

- data - Numeric matrix, n x dim.

- labels - Integer vector of 1-based cluster labels.

## Examples

``` r
dat <- generate_correlated_data(1000L, 32L, n_clusters = 5L)
```
