# Load an index from a directory

**\[experimental\]** Reads a bundle written by
[`rs_ann_save()`](https://gregorlueg.github.io/annsearchR/reference/rs_ann_save.md).
Use
[`load_ann_index()`](https://gregorlueg.github.io/annsearchR/reference/load_ann_index.md)
instead.

## Usage

``` r
rs_ann_load(dir, algo)
```

## Arguments

- dir:

  String. Directory holding `index.bin`.

- algo:

  String. Algorithm that wrote the bundle.

## Value

External pointer to the index.
