# Generate synthetic cell embeddings

Foundation-model cell embeddings in the style of Geneformer or scGPT. A
large shared mean offset puts every cell inside an anisotropy cone, a
few axis-aligned rogue dimensions dominate dot products, each cell type
varies in its own low-rank subspace, and a per-cell scale stands in for
library size. The nastiest of the four generators.

## Usage

``` r
generate_cell_embeddings(n, dim, n_clusters = 25L, seed = 42L)
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
dat <- generate_cell_embeddings(1000L, 64L, n_clusters = 8L)
```
