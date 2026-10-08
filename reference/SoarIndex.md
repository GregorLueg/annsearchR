# SOAR index

IVF with spilling: every point also lands in a second cell, picked by a
rule that accounts for the residual it carries in its first. Buys recall
at a given `nprobe` over
[IvfIndex](https://gregorlueg.github.io/annsearchR/reference/IvfIndex.md),
but scans about twice the candidates per probe, so compare the two on
query time, not on `nprobe`. No Manhattan.

## References

Sun et al., NeurIPS, 2023

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `SoarIndex`

## Active bindings

- `nprobe`:

  Integer or `NULL`. Cells visited per query.

## Methods

### Public methods

- [`SoarIndex$new()`](#method-SoarIndex-initialize)

- [`SoarIndex$clone()`](#method-SoarIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `SoarIndex$new()`

Build the index.

#### Usage

    SoarIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      nlist = NULL,
      nprobe = NULL,
      rule = NULL,
      rule_param = NULL,
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

- `rule`:

  String or `NULL`. Secondary assignment rule, one of
  `c("nearest", "shifted", "orthogonal")`. `NULL` picks orthogonal for
  cosine and shifted otherwise.

- `rule_param`:

  Numeric or `NULL`. `mu` for the shifted rule, `lambda` for the
  orthogonal one. `NULL` uses 0.5 and 1.0 respectively.

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

### `SoarIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    SoarIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- SoarIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
