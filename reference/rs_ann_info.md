# Describe an index

**\[experimental\]** Reads the algorithm, precision and shape off an
index pointer.

## Usage

``` r
rs_ann_info(ptr)
```

## Arguments

- ptr:

  External pointer to an index.

## Value

A list with:

- algo - Algorithm name.

- precision - `"float"` or `"double"`.

- n - Number of indexed samples.

- dim - Number of features.
