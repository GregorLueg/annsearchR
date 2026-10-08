# HNSW index

Hierarchical navigable small world graph. The usual first choice: high
recall at low query latency. Raise `ef_search` for recall at query time,
`ef_construction` for a better graph at build time.

Nodes are inserted in parallel, so two builds with the same `seed` give
slightly different graphs. Need bit-identical results? Build with
`ann_set_threads(1L)`.

## References

Malkov & Yashunin, IEEE TPAMI, 2020

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `HnswIndex`

## Active bindings

- `ef_search`:

  Integer. Beam width at query time.

## Methods

### Public methods

- [`HnswIndex$new()`](#method-HnswIndex-initialize)

- [`HnswIndex$clone()`](#method-HnswIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `HnswIndex$new()`

Build the index.

#### Usage

    HnswIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
      m = 16L,
      ef_construction = 200L,
      ef_search = 50L,
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

- `m`:

  Integer. Edges per node on the upper layers, `2 * m` on layer 0. 16
  suits most data; 32 to 48 helps in high dimensions.

- `ef_construction`:

  Integer. Candidate list width during the build. Better graph, slower
  build, no cost at query time.

- `ef_search`:

  Integer. Beam width at query time. Raised to `k` internally if
  smaller. Can be changed after the build.

- `seed`:

  Integer. Fixes the layer assignment.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

- `.verbose`:

  Boolean. Print build progress from Rust.

------------------------------------------------------------------------

### `HnswIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    HnswIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- HnswIndex$new(x, metric = "cosine")
idx$ef_search <- 100L
res <- idx$predict(x[1:5, ], k = 10L)
```
