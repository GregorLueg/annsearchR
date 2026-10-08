# Recall of an approximate kNN result against ground truth

**\[experimental\]** Use
[`knn_recall()`](https://gregorlueg.github.io/annsearchR/reference/knn_recall.md)
instead.

## Usage

``` r
rs_knn_recall(truth, approx)
```

## Arguments

- truth:

  Integer matrix. Queries x k true neighbour indices.

- approx:

  Integer matrix. Queries x k approximate neighbour indices, same shape
  as `truth`.

## Value

Numeric. Mean over queries of \|truth ∩ approx\| / k. `NA` entries in
`approx` never count as hits.
