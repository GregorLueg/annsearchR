# kd forest index

Forest of randomised kd spill-trees. Same trade as
[AnnoyIndex](https://gregorlueg.github.io/annsearchR/reference/AnnoyIndex.md)
with axis-aligned splits instead of random hyperplanes: more trees means
better recall and a larger index. Points near a split land in both
children, which lets one descent recover neighbours a hard split would
separate. The one tree index here that supports Manhattan.

## References

Muja & Lowe, IEEE TPAMI, 2014

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `KdTreeIndex`

## Active bindings

- `search_budget`:

  Integer or `NULL`. Candidates inspected per query.

## Methods

### Public methods

- [`KdTreeIndex$new()`](#method-KdTreeIndex-initialize)

- [`KdTreeIndex$clone()`](#method-KdTreeIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `KdTreeIndex$new()`

Build the index.

#### Usage

    KdTreeIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      n_trees = 25L,
      search_budget = NULL,
      seed = 42L,
      precision = c("float", "double")
    )

#### Arguments

- `data`:

  Numeric matrix or data.frame. Samples x features. An index pointer is
  also accepted;
  [`load_ann_index()`](https://gregorlueg.github.io/annsearchR/reference/load_ann_index.md)
  uses that path.

- `metric`:

  String. One of `c("euclidean", "sqeuclidean", "cosine", "manhattan")`.

- `n_trees`:

  Integer. Number of trees in the forest.

- `search_budget`:

  Integer or `NULL`. Candidates inspected per query. `NULL` uses
  `k * n_trees * 20`. Can be changed after the build.

- `seed`:

  Integer. Fixes the split dimensions.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

------------------------------------------------------------------------

### `KdTreeIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    KdTreeIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- KdTreeIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
