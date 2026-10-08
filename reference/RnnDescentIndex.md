# Relative NN-Descent index

Builds and prunes a navigable graph in one pass, skipping the separate
refinement step
[NsgIndex](https://gregorlueg.github.io/annsearchR/reference/NsgIndex.md)
pays for. `r` caps the out-degree, `ef_search` is the recall knob. On
Gaussian benchmark data it tops out around 0.97 recall, so check it
reaches what you need.

## References

Ono & Matsui, ACM MM, 2023

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `RnnDescentIndex`

## Active bindings

- `ef_search`:

  Integer or `NULL`. Beam width at query time.

- `k_search`:

  Integer or `NULL`. Neighbours expanded per hop.

## Methods

### Public methods

- [`RnnDescentIndex$new()`](#method-RnnDescentIndex-initialize)

- [`RnnDescentIndex$clone()`](#method-RnnDescentIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `RnnDescentIndex$new()`

Build the index.

#### Usage

    RnnDescentIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      s = 20L,
      r = 96L,
      t1 = 4L,
      t2 = 15L,
      n_trees = NULL,
      ef_search = NULL,
      k_search = NULL,
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

- `s`:

  Integer. Neighbours sampled per node per local join.

- `r`:

  Integer. Maximum out-degree after pruning.

- `t1`:

  Integer. Outer iterations.

- `t2`:

  Integer. Inner descent iterations per outer one.

- `n_trees`:

  Integer or `NULL`. Random projection trees for the seed graph. `NULL`
  uses `min(5 + n^0.25 / 2, 16)`.

- `ef_search`:

  Integer or `NULL`. Beam width at query time. `NULL` uses 100. Can be
  changed after the build.

- `k_search`:

  Integer or `NULL`. Neighbours expanded per hop. `NULL` uses 32, capped
  at `r`. Can be changed after the build.

- `seed`:

  Integer. Fixes the seed graph and the sampling.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

- `.verbose`:

  Boolean. Print build progress from Rust.

------------------------------------------------------------------------

### `RnnDescentIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    RnnDescentIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- RnnDescentIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
