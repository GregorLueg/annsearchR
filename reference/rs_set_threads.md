# Set the number of threads used for builds and queries

**\[experimental\]** Installs a dedicated Rayon pool. Use
[`ann_set_threads()`](https://gregorlueg.github.io/annsearchR/reference/ann_set_threads.md)
instead.

## Usage

``` r
rs_set_threads(n)
```

## Arguments

- n:

  Integer. Thread count. `0L` returns to Rayon's global pool, which
  honours `RAYON_NUM_THREADS`.

## Value

Invisible `NULL`.
