# Generate clustered synthetic data

Separated Gaussian clusters, with a fifth of the points on thin bridges
between neighbouring clusters so the boundaries aren't trivially clean.
The baseline of the four generators.

All generators are the ones behind the Rust crate's benchmark tables.
They draw in f32 like the crate's gridsearch examples and the Python
bindings, so the same seed gives the same points in all three.

## Usage

``` r
generate_clustered_data(n, dim, n_clusters = 25L, seed = 42L)
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

A list with:

- data - Numeric matrix, n x dim.

- labels - Integer vector of 1-based cluster labels.

## Examples

``` r
dat <- generate_clustered_data(1000L, 16L, n_clusters = 5L)
table(dat$labels)
#> 
#>   1   2   3   4   5 
#> 172 133 168 243 284 
```
