# Coerce and validate a data matrix for the Rust side

Coerce and validate a data matrix for the Rust side

## Usage

``` r
.as_ann_matrix(x, dim = NULL, .var.name = "data")
```

## Arguments

- x:

  Numeric matrix or data.frame of numeric columns. Samples x features.
  No missing values.

- dim:

  Optional integer. Required number of columns.

- .var.name:

  String. Name used in error messages.

## Value

A double matrix.
