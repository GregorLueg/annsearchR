# IVF index

Inverted file over k-means Voronoi cells. Cheap to build and easy to
tune: `nlist` sets how finely the space is cut, `nprobe` how many cells
a query visits. The smallest of the unquantised approximate indices. No
Manhattan.

## References

Sivic J, Zisserman A (2003). Video Google: a text retrieval approach to
object matching in videos. *Proceedings Ninth IEEE International
Conference on Computer Vision*, 1470-1477.
[doi:10.1109/ICCV.2003.1238663](https://doi.org/10.1109/ICCV.2003.1238663)

Jégou H, Douze M, Schmid C (2011). Product quantization for nearest
neighbor search. *IEEE Transactions on Pattern Analysis and Machine
Intelligence*, 33, 117-128.
[doi:10.1109/TPAMI.2010.57](https://doi.org/10.1109/TPAMI.2010.57)

Bessa S, Mazaré P-E, Szilvasy G, Touvron H, Picard D, Douze M, Jégou H
(2026). e-means: outperforming k-means (in one-tenth the epochs).
*arXiv*. <https://arxiv.org/abs/2611.09501>

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

  Integer or `NULL`. `NULL` trains the centroids with e-means at its own
  epoch budget. An integer switches to Lloyd's with that many
  iterations.

- `kmeans_balanced`:

  Boolean. Reseed starved centroids each iteration. Only affects Lloyd's
  k-means, i.e. when `kmeans_iters` is set. Ignored otherwise: e-means,
  the default, has no balancing option.

- `seed`:

  Integer. Fixes the k-means initialisation.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

- `.verbose`:

  Boolean or integer. Build progress from Rust: `0` or `FALSE` silent,
  `1` or `TRUE` progress, `2` adds timed build stages.

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
