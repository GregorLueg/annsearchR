# Build an LSH index

**\[experimental\]** Use
[LshIndex](https://gregorlueg.github.io/annsearchR/reference/LshIndex.md)
instead.

## Usage

``` r
rs_lsh_build(
  data,
  metric,
  num_tables,
  bits_per_hash,
  slot_bits,
  seed,
  precision
)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine")`.

- num_tables:

  Integer. Independent hash tables.

- bits_per_hash:

  Integer. Bits per bucket code.

- slot_bits:

  Integer or `NULL`. Bits per quantised projection.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

## Value

External pointer to the index.
