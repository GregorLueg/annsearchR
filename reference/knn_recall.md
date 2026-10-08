# Recall of an approximate kNN result

Fraction of the true `k` nearest neighbours that the approximate search
found, averaged over queries. Order within a row does not matter.

## Usage

``` r
knn_recall(truth, approx, k = NULL)
```

## Arguments

- truth:

  Integer matrix. Queries x k true neighbour indices, e.g. the `idx`
  element from an
  [ExhaustiveIndex](https://gregorlueg.github.io/annsearchR/reference/ExhaustiveIndex.md).

- approx:

  Integer matrix. Queries x k approximate neighbour indices.

- k:

  Optional integer. Only the first `k` columns of both are compared.
  Defaults to `ncol(approx)`.

## Value

Numeric between 0 and 1.
