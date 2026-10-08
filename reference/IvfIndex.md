# IVF index

Inverted file over k-means Voronoi cells. Cheap to build and easy to
tune: `nlist` sets how finely the space is cut, `nprobe` how many cells
a query visits. The smallest of the unquantised approximate indices. No
Manhattan.

## References

Jégou, Douze & Schmid, IEEE TPAMI, 2011

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `IvfIndex`

## Active bindings

- `nprobe`:

  Integer or `NULL`. Cells visited per query.

## Methods

### Public methods

- [`IvfIndex$new()`](#method-IvfIndex-initialize)

- [`IvfIndex$clone()`](#method-IvfIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `IvfIndex$new()`

Build the index.

#### Usage

    IvfIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      nlist = NULL,
      nprobe = NULL,
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

  Integer or `NULL`. Number of Voronoi cells. `NULL` uses `sqrt(n)`.

- `nprobe`:

  Integer or `NULL`. Cells visited per query. `NULL` uses `sqrt(nlist)`.
  Can be changed after the build.

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

### `IvfIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    IvfIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- IvfIndex$new(x)
idx$nprobe <- 10L
res <- idx$predict(x[1:5, ], k = 10L)
```
