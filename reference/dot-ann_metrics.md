# Metric names and how they map onto the Rust core

The core works in squared Euclidean, so `"euclidean"` carries a flag to
square root the distances on the way out. The core also silently falls
back to squared Euclidean on a string it does not know, which is why
every metric is validated here before it gets anywhere near Rust.

## Usage

``` r
.ann_metrics()
```

## Value

A named list. Each element has `core` (string passed to Rust) and `sqrt`
(boolean).
