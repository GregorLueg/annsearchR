# Base class for all nearest neighbour indices

Holds a pointer to an index living in Rust memory, plus the bits R needs
to talk to it (metric, precision, shape). Never instantiated directly:
use one of the algorithm classes such as
[HnswIndex](https://gregorlueg.github.io/annsearchR/reference/HnswIndex.md),
[AnnoyIndex](https://gregorlueg.github.io/annsearchR/reference/AnnoyIndex.md)
or
[ExhaustiveIndex](https://gregorlueg.github.io/annsearchR/reference/ExhaustiveIndex.md).

The index itself is not serialised by
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html). A restored object
holds a dead pointer and every method errors. Use `$save()` and
[`load_ann_index()`](https://gregorlueg.github.io/annsearchR/reference/load_ann_index.md)
instead.

## Active bindings

- `n`:

  Integer. Number of indexed samples. Read-only.

- `dim`:

  Integer. Number of features. Read-only.

- `metric`:

  String. Distance metric. Read-only.

- `precision`:

  String. `"float"` or `"double"`. Read-only.

## Methods

### Public methods

- [`AnnIndex$predict()`](#method-AnnIndex-predict)

- [`AnnIndex$query_self()`](#method-AnnIndex-query_self)

- [`AnnIndex$save()`](#method-AnnIndex-save)

- [`AnnIndex$print()`](#method-AnnIndex-print)

- [`AnnIndex$clone()`](#method-AnnIndex-clone)

------------------------------------------------------------------------

### `AnnIndex$predict()`

Find the `k` nearest indexed samples for each row of `newdata`.

#### Usage

    AnnIndex$predict(newdata, k = 15L, return_dist = TRUE, .verbose = FALSE)

#### Arguments

- `newdata`:

  Numeric matrix or data.frame. Queries x features, same number of
  features as the index.

- `k`:

  Integer. Number of neighbours.

- `return_dist`:

  Boolean. Return the distances as well.

- `.verbose`:

  Boolean. Print progress from Rust.

#### Returns

A list with:

- idx - Integer matrix, queries x k. 1-based row indices into the
  indexed data. `NA` where fewer than `k` neighbours were found.

- dist - Numeric matrix, queries x k, or `NULL` if
  `return_dist = FALSE`. `Inf` where `idx` is `NA`.

------------------------------------------------------------------------

### `AnnIndex$query_self()`

kNN graph over the indexed data itself. Uses each index's own self-query
path, which is faster than `$predict()` on the training data.

#### Usage

    AnnIndex$query_self(k = 15L, return_dist = TRUE, .verbose = FALSE)

#### Arguments

- `k`:

  Integer. Number of neighbours, including the sample itself.

- `return_dist`:

  Boolean. Return the distances as well.

- `.verbose`:

  Boolean. Print progress from Rust.

#### Returns

A list with `idx` and `dist`, as for `$predict()`, with one row per
indexed sample.

------------------------------------------------------------------------

### `AnnIndex$save()`

Write the index to a directory. Read it back with
[`load_ann_index()`](https://gregorlueg.github.io/annsearchR/reference/load_ann_index.md).

#### Usage

    AnnIndex$save(dir)

#### Arguments

- `dir`:

  String. Target directory, created if missing.

#### Returns

The object, invisibly.

------------------------------------------------------------------------

### `AnnIndex$print()`

Print a one-line summary.

#### Usage

    AnnIndex$print(...)

#### Arguments

- `...`:

  Ignored.

#### Returns

The object, invisibly.

------------------------------------------------------------------------

### `AnnIndex$clone()`

The objects of this class are cloneable with this method.

#### Usage

    AnnIndex$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
