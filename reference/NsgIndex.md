# NSG index

Navigating spreading-out graph. Builds an NN-Descent kNN graph of degree
`knn_k` first, then refines it into a sparse monotonic graph. Smallest
of the graph indices; pays for it with a double build.

## References

Fu et al., VLDB, 2019

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `NsgIndex`

## Active bindings

- `ef_search`:

  Integer or `NULL`. Beam width at query time.

## Methods

### Public methods

- [`NsgIndex$new()`](#method-NsgIndex-initialize)

- [`NsgIndex$clone()`](#method-NsgIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `NsgIndex$new()`

Build the index.

#### Usage

    NsgIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      r = 32L,
      l_build = 100L,
      c = 500L,
      knn_k = 64L,
      ef_search = NULL,
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

- `r`:

  Integer. Maximum out-degree of the refined graph.

- `l_build`:

  Integer. Candidate list width while refining.

- `c`:

  Integer. Candidate pool size per node before pruning.

- `knn_k`:

  Integer. Degree of the NN-Descent graph built first. Wants to be
  comfortably above `r`.

- `ef_search`:

  Integer or `NULL`. Beam width at query time. `NULL` uses 100. Can be
  changed after the build.

- `seed`:

  Integer. Fixes the initial graph and navigating node.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

- `.verbose`:

  Boolean. Print build progress from Rust.

------------------------------------------------------------------------

### `NsgIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    NsgIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- NsgIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
