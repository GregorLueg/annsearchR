# Build an NSG index

**\[experimental\]** Use
[NsgIndex](https://gregorlueg.github.io/annsearchR/reference/NsgIndex.md)
instead.

## Usage

``` r
rs_nsg_build(data, metric, r, l_build, c, knn_k, seed, precision, verbose)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine", "manhattan")`.

- r:

  Integer. Maximum out-degree of the refined graph.

- l_build:

  Integer. Candidate list width while refining.

- c:

  Integer. Candidate pool size per node before pruning.

- knn_k:

  Integer. Degree of the NN-Descent graph built first.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Boolean. Print progress.

## Value

External pointer to the index.
