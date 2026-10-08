# Ball tree index

Metric tree of nested hyperspheres, pruned by the triangle inequality.
Pays off on data with real cluster structure at moderate dimensionality.
The default search budget (5% of the indexed points) makes it
approximate; raise it for recall. Past about 10% recall plateaus and
query time does not fall. No Manhattan.

## References

Omohundro, ICSI Technical Report, 1989

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `BallTreeIndex`

## Active bindings

- `search_budget`:

  Integer or `NULL`. Points inspected per query.

## Methods

### Public methods

- [`BallTreeIndex$new()`](#method-BallTreeIndex-initialize)

- [`BallTreeIndex$clone()`](#method-BallTreeIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `BallTreeIndex$new()`

Build the index.

#### Usage

    BallTreeIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
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

  String. One of `c("euclidean", "sqeuclidean", "cosine")`.

- `search_budget`:

  Integer or `NULL`. Points inspected per query. `NULL` uses 5% of the
  indexed points. Can be changed after the build.

- `seed`:

  Integer. Fixes the pivot choice at each split.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

------------------------------------------------------------------------

### `BallTreeIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    BallTreeIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- BallTreeIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
