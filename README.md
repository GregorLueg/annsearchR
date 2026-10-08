# annsearchR <img src="man/figures/logo.png" align="right" height="138" alt="annsearchR logo" />

[![r_package](https://img.shields.io/github/r-package/v/GregorLueg/annsearchR?label=R_package&color=orange)](https://github.com/GregorLueg/annsearchR/blob/main/DESCRIPTION)
[![CI](https://github.com/GregorLueg/annsearchR/actions/workflows/R-cmd-check.yml/badge.svg)](https://github.com/GregorLueg/annsearchR/actions/workflows/R-cmd-check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pkgdown](https://img.shields.io/badge/pkgdown-website-1b5e9f?logo=github)](https://gregorlueg.github.io/annsearchR/)
[![extendr](https://img.shields.io/badge/extendr-^0.9.0-276DC2)](https://extendr.github.io/extendr/extendr_api/)

**Rust-accelerated** exact and approximate nearest neighbour search for R.
Build an index once, keep it in memory behind an R6 object and query it as
often as you like. The backbone is the Rust crate
[ann-search-rs](https://github.com/GregorLueg/ann-search-rs).

## Overview

### Indices

Thirteen CPU indices, all behind the same `$new()` / `$predict()` interface:

- **Exact:** brute force (SIMD, and Apple Accelerate on macOS) and kMkNN
- **Trees:** Annoy, k-d forest and ball tree
- **Partitions:** IVF, SOAR and LSH
- **Graphs:** HNSW, NN-Descent, Vamana, NSG and RNN-Descent

Euclidean, squared Euclidean, cosine and Manhattan distances, f32 or f64
storage, multi-threaded via Rayon. Indices can be saved to disk and loaded
back, and `$query_self()` gives you the kNN graph of the indexed data itself.

### Speed

At equal recall on the [ann-benchmarks](https://ann-benchmarks.com) datasets,
annsearchR's HNSW runs about 2x the queries per second of RcppHNSW with 10
threads and 3.6 to 4x on one thread. NN-Descent is 4.5 to 23x faster than
rnndescent and Annoy 1.5 to 3.7x faster than RcppAnnoy. The full comparison
against RcppHNSW, RcppAnnoy, BiocNeighbors, rnndescent, FNN and RANN on
Fashion-MNIST and SIFT-128 is in the
[benchmarks article](https://gregorlueg.github.io/annsearchR/articles/benchmarks.html).

## Installation

### Prerequisites

This package requires Rust to be installed on your system. If you don't have
Rust installed:

**macOS and Linux:**

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**Windows:**

Download and run the installer from [rustup.rs](https://rustup.rs/)

After installation, restart your terminal and verify Rust is installed:

```bash
rustc --version
```

### Install annsearchR

Install from source. That will compile all of the Rust crates from scratch.

```r
remotes::install_github("GregorLueg/annsearchR")
```

## How to use the package ... ?

```r
library(annsearchR)

dat <- generate_clustered_data(20000L, 32L)$data
hnsw <- HnswIndex$new(dat[-(1:500), ], metric = "cosine")
res <- hnsw$predict(dat[1:500, ], k = 10L)
```

For everything else, please check out the
[website](https://gregorlueg.github.io/annsearchR/index.html) and the
[getting started vignette](https://gregorlueg.github.io/annsearchR/articles/annsearchR.html).

## License

Copyright (c) 2026 annsearchR authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
