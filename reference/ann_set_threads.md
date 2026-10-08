# Set the number of threads for index builds and queries

Installs a dedicated thread pool for all subsequent builds and queries.
Can be called as often as you like.

## Usage

``` r
ann_set_threads(n)
```

## Arguments

- n:

  Integer. Number of threads. `0L` returns to the default pool, which
  uses all cores or honours `RAYON_NUM_THREADS` if set.

## Value

The previous thread count, invisibly.
