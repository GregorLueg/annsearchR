# Build a Vamana index

**\[experimental\]** Use
[VamanaIndex](https://gregorlueg.github.io/annsearchR/reference/VamanaIndex.md)
instead.

## Usage

``` r
rs_vamana_build(
  data,
  metric,
  r,
  l_build,
  alpha_pass1,
  alpha_pass2,
  seed,
  precision,
  verbose
)
```

## Arguments

- data:

  Numeric matrix. Samples x features.

- metric:

  String. One of `c("euclidean", "cosine", "manhattan")`.

- r:

  Integer. Maximum out-degree.

- l_build:

  Integer. Candidate list width during the build.

- alpha_pass1:

  Numeric. Relaxation factor on the first pass.

- alpha_pass2:

  Numeric. Relaxation factor on the second pass.

- seed:

  Integer. Random seed.

- precision:

  String. `"float"` or `"double"`.

- verbose:

  Integer. 0 silent, 1 progress, 2 detailed.

## Value

External pointer to the index.
