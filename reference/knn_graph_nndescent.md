# kNN graph by NN-Descent, without an index

Matrix in, kNN graph out. Runs the same descent as
[NNDescentIndex](https://gregorlueg.github.io/annsearchR/reference/NNDescentIndex.md),
but drops the seeding trees as soon as they are joined and keeps no
index, so peak memory stays near the data plus the graph. At the same
`seed`, `n_trees` and descent parameters, the result is identical to
`NNDescentIndex$new(...)$extract_knn()`. Use
[NNDescentIndex](https://gregorlueg.github.io/annsearchR/reference/NNDescentIndex.md)
if you also want to query the graph with new data.

`k_graph` is the number of neighbours the descent finds per sample, the
sample itself not counted. With `include_self = TRUE` (the default, as
for `$query_self()`) each row starts with the sample itself at distance
0, so the matrices have `k_graph + 1` columns. With
`include_self = FALSE` they have `k_graph` columns of true neighbours
only.

## Usage

``` r
knn_graph_nndescent(
  data,
  metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
  k_graph = 15L,
  delta = 0.001,
  max_iter = NULL,
  max_candidates = NULL,
  n_trees = NULL,
  include_self = TRUE,
  return_dist = TRUE,
  seed = 42L,
  precision = c("float", "double"),
  .verbose = FALSE
)
```

## Arguments

- data:

  Numeric matrix or data.frame. Samples x features.

- metric:

  String. One of `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.

- k_graph:

  Integer. Neighbours per sample found by the descent, the sample itself
  not counted.

- delta:

  Numeric. Convergence threshold: descent stops once the fraction of
  updated edges falls below it.

- max_iter:

  Integer or `NULL`. Iteration cap. `NULL` uses
  `max(round(log2(n)), 5)`.

- max_candidates:

  Integer or `NULL`. Neighbours sampled per node per local join. `NULL`
  uses `min(k_graph, 60)`.

- n_trees:

  Integer or `NULL`. Random projection trees for the seed graph. `NULL`
  uses `min(5 + round(sqrt(n) / 20), 64)`.

- include_self:

  Boolean. Put each sample first at distance 0, adding one column.

- return_dist:

  Boolean. Return the distances as well.

- seed:

  Integer. Fixes the seed graph and the sampling.

- precision:

  String. `"float"` runs the descent in f32, `"double"` in f64.

- .verbose:

  Boolean or integer. Build progress from Rust: `0` or `FALSE` silent,
  `1` or `TRUE` progress, `2` adds timed build stages.

## Value

A list with:

- idx - Integer matrix, samples x (`k_graph + include_self`), 1-based
  neighbour indices sorted by distance. Rows the descent could not fill
  are `NA` padded.

- dist - Double matrix of the same shape with the distances, `Inf` where
  `idx` is `NA`. `NULL` if `return_dist = FALSE`.

## References

Dong W, Charikar M, Li K (2011). Efficient k-nearest neighbor graph
construction for generic similarity measures. *Proceedings of the 20th
International Conference on World Wide Web*, 577-586.
[doi:10.1145/1963405.1963487](https://doi.org/10.1145/1963405.1963487)

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
knn <- knn_graph_nndescent(x, k_graph = 15L)
dim(knn$idx)
#> [1] 1000   16
```
