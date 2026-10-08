# Load an index written by `$save()`

Reads the index bundle and its R-side parameters (metric, search knobs)
back into the matching
[AnnIndex](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
subclass. The float width is read from the bundle. Bundles are tied to
the on-disk format version of the underlying Rust crate; a format bump
means rebuilding.

## Usage

``` r
load_ann_index(dir)
```

## Arguments

- dir:

  String. Directory written by `$save()`.

## Value

An
[AnnIndex](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
subclass, ready to query.
