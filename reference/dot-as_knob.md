# Validate a search-time knob

Validate a search-time knob

## Usage

``` r
.as_knob(value, null_ok = TRUE, .var.name = "value")
```

## Arguments

- value:

  Positive integer, or `NULL` if `null_ok`.

- null_ok:

  Boolean. Whether `NULL` (let the crate pick) is allowed.

- .var.name:

  String. Name used in error messages.

## Value

`value` as integer, or `NULL`.
