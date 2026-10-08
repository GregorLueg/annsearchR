# Generate synthetic cell embeddings

**\[experimental\]** Foundation-model style cell embeddings: anisotropy
cone, rogue dimensions and heavy-tailed spectrum. Use
[`generate_cell_embeddings()`](https://gregorlueg.github.io/annsearchR/reference/generate_cell_embeddings.md)
instead.

## Usage

``` r
rs_data_cell_embeddings(n, dim, n_clusters, seed)
```

## Arguments

- n:

  Integer. Number of cells.

- dim:

  Integer. Embedding width.

- n_clusters:

  Integer. Number of cell types.

- seed:

  Integer. Random seed.

## Value

A list with `data` (n x dim numeric matrix) and `labels` (1-based
integer cluster labels).
