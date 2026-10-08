# NN-Descent index

Builds the kNN graph directly by iterative local join. Want the kNN
graph of the data itself (UMAP, clustering)? `$extract_knn()` hands back
the converged graph without any search, far cheaper than
`$query_self()`. It reads the post-pruning graph, so leave
`diversify_prob` at 0 if extraction is the point.

## References

Dong, Moses & Li, WWW, 2011

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `NNDescentIndex`

## Active bindings

- `ef_search`:

  Integer or `NULL`. Beam width at query time.

- `k_graph`:

  Integer. Degree of the built graph. Read-only.

## Methods

### Public methods

- [`NNDescentIndex$new()`](#method-NNDescentIndex-initialize)

- [`NNDescentIndex$extract_knn()`](#method-NNDescentIndex-extract_knn)

- [`NNDescentIndex$clone()`](#method-NNDescentIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `NNDescentIndex$new()`

Build the index.

#### Usage

    NNDescentIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      k_graph = 15L,
      delta = 0.001,
      diversify_prob = 0,
      max_iter = NULL,
      max_candidates = NULL,
      n_trees = NULL,
      ef_search = NULL,
      seed = 42L,
      precision = c("float", "double"),
      .verbose = FALSE
    )

#### Arguments

- `data`:

  Numeric matrix or data.frame. Samples x features. An index pointer is
  also accepted;
  [`load_ann_index()`](https://gregorlueg.github.io/annsearchR/reference/load_ann_index.md)
  uses that path.

- `metric`:

  String. One of `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.

- `k_graph`:

  Integer. Neighbours per node in the graph being built.

- `delta`:

  Numeric. Convergence threshold: descent stops once the fraction of
  updated edges falls below it.

- `diversify_prob`:

  Numeric between 0 and 1. Probability of pruning an occluded edge after
  descent. `0` disables pruning.

- `max_iter`:

  Integer or `NULL`. Iteration cap. `NULL` uses
  `max(round(log2(n)), 5)`.

- `max_candidates`:

  Integer or `NULL`. Neighbours sampled per node per local join. `NULL`
  uses `min(k_graph, 60)`.

- `n_trees`:

  Integer or `NULL`. Random projection trees for the seed graph. `NULL`
  uses `min(5 + round(n^0.25), 12)`.

- `ef_search`:

  Integer or `NULL`. Beam width at query time. `NULL` uses
  `clamp(2 * k, 50, 200)`. Can be changed after the build.

- `seed`:

  Integer. Fixes the seed graph and the sampling.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

- `.verbose`:

  Boolean. Print build progress from Rust.

------------------------------------------------------------------------

### `NNDescentIndex$extract_knn()`

The converged kNN graph over the indexed data, read straight off the
index. No search involved.

#### Usage

    NNDescentIndex$extract_knn(k = NULL, include_self = TRUE, return_dist = TRUE)

#### Arguments

- `k`:

  Integer or `NULL`. Row length, including the sample itself when
  `include_self = TRUE`. `NULL` uses the graph degree `k_graph`.

- `include_self`:

  Boolean. Put each sample first at distance 0, as `$query_self()` does.

- `return_dist`:

  Boolean. Return the distances as well.

#### Returns

A list with `idx` and `dist`, as for `$predict()`, with one row per
indexed sample. Rows the graph cannot fill are `NA` padded.

------------------------------------------------------------------------

### `NNDescentIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    NNDescentIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- NNDescentIndex$new(x, k_graph = 15L)
knn <- idx$extract_knn()
```
