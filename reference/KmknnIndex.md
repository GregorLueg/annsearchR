# kMkNN index

Exact search over a k-means partition, pruning whole clusters by the
triangle inequality. Same answers as
[ExhaustiveIndex](https://gregorlueg.github.io/annsearchR/reference/ExhaustiveIndex.md);
whether it is faster depends on how well the data clusters, so time
both. No Manhattan.

## References

Wang, IEEE ICDMW, 2012

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `KmknnIndex`

## Methods

### Public methods

- [`KmknnIndex$new()`](#method-KmknnIndex-initialize)

- [`KmknnIndex$clone()`](#method-KmknnIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `KmknnIndex$new()`

Build the index.

#### Usage

    KmknnIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      nlist = NULL,
      kmeans_iters = NULL,
      kmeans_balanced = FALSE,
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

  String. One of `c("euclidean", "sqeuclidean", "cosine")`.

- `nlist`:

  Integer or `NULL`. Number of k-means clusters. `NULL` uses `sqrt(n)`.

- `kmeans_iters`:

  Integer or `NULL`. Lloyd iterations. `NULL` uses 30.

- `kmeans_balanced`:

  Boolean. Reseed starved centroids each iteration.

- `seed`:

  Integer. Fixes the k-means initialisation.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

- `.verbose`:

  Boolean. Print build progress from Rust.

------------------------------------------------------------------------

### `KmknnIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KmknnIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- KmknnIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
