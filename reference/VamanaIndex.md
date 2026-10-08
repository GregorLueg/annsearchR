# Vamana index

The flat graph from DiskANN: out-degree `r`, pruned in two passes with
the relaxed-neighbour rule. Builds slower than
[HnswIndex](https://gregorlueg.github.io/annsearchR/reference/HnswIndex.md)
at its cheapest setting, though the gap closes once you match on recall,
and the index is a few per cent smaller.

## References

Subramanya et al., NeurIPS, 2019

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `VamanaIndex`

## Active bindings

- `ef_search`:

  Integer or `NULL`. Beam width at query time.

## Methods

### Public methods

- [`VamanaIndex$new()`](#method-VamanaIndex-initialize)

- [`VamanaIndex$clone()`](#method-VamanaIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `VamanaIndex$new()`

Build the index.

#### Usage

    VamanaIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      r = 48L,
      l_build = 100L,
      alpha_pass1 = 1,
      alpha_pass2 = 1.2,
      ef_search = NULL,
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

- `r`:

  Integer. Maximum out-degree.

- `l_build`:

  Integer. Candidate list width during the build.

- `alpha_pass1`:

  Numeric. Relaxed-neighbour factor on the first pruning pass. `1` is
  the plain rule.

- `alpha_pass2`:

  Numeric. Same on the second pass. Above 1 keeps longer edges, which
  keeps the graph navigable from far away.

- `ef_search`:

  Integer or `NULL`. Beam width at query time. `NULL` uses 75. Can be
  changed after the build.

- `seed`:

  Integer. Fixes the entry point and pruning order.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

------------------------------------------------------------------------

### `VamanaIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    VamanaIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- VamanaIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
