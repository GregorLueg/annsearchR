# Validate a verbosity flag

Validate a verbosity flag

## Usage

``` r
.as_verbosity(value, .var.name = ".verbose")
```

## Arguments

- value:

  Boolean, or integer in `0:2`. `TRUE` maps to 1, `FALSE` to 0.

- .var.name:

  String. Name used in error messages.

## Value

`value` as integer, one of `0:2`.
