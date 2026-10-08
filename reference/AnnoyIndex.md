# Annoy index

Random projection forest, as in Spotify's Annoy. More trees means better
recall, a larger index and a slower build. Raise `search_budget` for
recall at query time. No Manhattan.

## References

Bernhardsson, Annoy, <https://github.com/spotify/annoy>

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `AnnoyIndex`

## Active bindings

- `search_budget`:

  Integer or `NULL`. Candidates inspected per query.

## Methods

### Public methods

- [`AnnoyIndex$new()`](#method-AnnoyIndex-initialize)

- [`AnnoyIndex$clone()`](#method-AnnoyIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `AnnoyIndex$new()`

Build the index.

#### Usage

    AnnoyIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
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

  String. One of `c("euclidean", "sqeuclidean", "cosine")`.

- `n_trees`:

  Integer. Number of trees in the forest.

- `search_budget`:

  Integer or `NULL`. Candidates inspected per query. `NULL` uses
  `k * n_trees * 20`. Can be changed after the build.

- `seed`:

  Integer. Fixes the random hyperplanes.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

------------------------------------------------------------------------

### `AnnoyIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    AnnoyIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- AnnoyIndex$new(x, n_trees = 25L)
res <- idx$predict(x[1:5, ], k = 10L)
```
