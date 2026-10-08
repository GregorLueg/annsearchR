# Build an HNSW index

**\[experimental\]** Use
[HnswIndex](https://gregorlueg.github.io/annsearchR/reference/HnswIndex.md)
instead.

## Usage

``` r
rs_hnsw_build(data, metric, m, ef_construction, seed, precision, verbose)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine", "manhattan")`.

- m:

  Integer. Edges per node on the upper layers.

- ef_construction:

  Integer. Candidate list width during the build.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Boolean. Print progress.

## Value

External pointer to the index.
