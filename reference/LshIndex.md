# LSH index

Multi-probe locality-sensitive hashing over random projections. By far
the cheapest index to build here, and the weakest on recall for the
query time it costs; the one index whose query can come out slower than
brute force. Fewer `bits_per_hash` widens the buckets, more `num_tables`
trades memory for recall. No Manhattan.

## References

Lv et al., VLDB, 2007

## Super class

[`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
-\> `LshIndex`

## Active bindings

- `n_probe`:

  Integer or `NULL`. Buckets probed per table.

- `max_candidates`:

  Integer or `NULL`. Cap on candidates scored.

## Methods

### Public methods

- [`LshIndex$new()`](#method-LshIndex-initialize)

- [`LshIndex$clone()`](#method-LshIndex-clone)

Inherited methods

- [`AnnIndex$predict()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-predict)
- [`AnnIndex$print()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-print)
- [`AnnIndex$query_self()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-query_self)
- [`AnnIndex$save()`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.html#method-save)

------------------------------------------------------------------------

### `LshIndex$new()`

Build the index.

#### Usage

    LshIndex$new(
      data,
      metric = c("euclidean", "sqeuclidean", "cosine"),
      num_tables = 8L,
      bits_per_hash = 12L,
      slot_bits = NULL,
      n_probe = NULL,
      max_candidates = NULL,
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

- `num_tables`:

  Integer. Independent hash tables.

- `bits_per_hash`:

  Integer. Total bits in a bucket code.

- `slot_bits`:

  Integer or `NULL`. Bits each quantised projection contributes. `NULL`
  uses 1 for cosine and 2 otherwise.

- `n_probe`:

  Integer or `NULL`. Buckets probed per table. `NULL` uses one per
  projection. Can be changed after the build.

- `max_candidates`:

  Integer or `NULL`. Cap on candidates scored per query. `NULL` means no
  cap. Can be changed after the build.

- `seed`:

  Integer. Fixes the random projections.

- `precision`:

  String. `"float"` stores the data as f32, `"double"` as f64.

------------------------------------------------------------------------

### `LshIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    LshIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
x <- generate_clustered_data(1000L, 16L)$data
idx <- LshIndex$new(x)
res <- idx$predict(x[1:5, ], k = 10L)
```
