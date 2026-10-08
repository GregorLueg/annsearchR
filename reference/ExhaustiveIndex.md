# Exhaustive (brute-force) index

Exact search: every query is compared to every indexed sample, SIMD
accelerated and multi-threaded. The ground truth to measure the
approximate indices against, and faster than you might think up to a few
hundred thousand samples. Large query batches go through a blocked GEMM
path, which on macOS runs on Apple Accelerate, so it can outrun the
thread count set by
[`ann_set_threads()`](https://gregorlueg.github.io/annsearchR/reference/ann_set_threads.md).

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `ExhaustiveIndex`

## Methods

### Public methods

- [`ExhaustiveIndex$new()`](#method-ExhaustiveIndex-initialize)

- [`ExhaustiveIndex$clone()`](#method-ExhaustiveIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `ExhaustiveIndex$new()`

Build the index.

#### Usage

    ExhaustiveIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine", "manhattan"),
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

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

------------------------------------------------------------------------

### `ExhaustiveIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    ExhaustiveIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- ExhaustiveIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
