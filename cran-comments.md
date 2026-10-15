## Resubmission

This is a resubmission. The first submission failed the incoming pre-tests.
In this version I have:

- Fixed the installation ERROR on Windows. The install also built a helper
  binary that regenerates the R wrappers, and linking it hit the Windows
  path length limit. That binary now only builds during development
  (under roxygen2), never at install.
- Updated the extendr URL in README.md, which had moved.
- Removed the ICSI URL from the BallTreeIndex references, which timed out.
  The citation itself stays.

## Submission

First submission.

## Rust

The package wraps the Rust crate 'ann-search-rs' via 'extendr'. It follows
the CRAN guidance for Rust packages:

- All crates are vendored in `src/rust/vendor.tar.xz` (xz compressed) and the
  build runs `cargo build --offline -j 2`, so nothing is downloaded at install.
- `CARGO_HOME` points into `src/.cargo` during the build and is removed
  afterwards, so nothing is written to the user's home directory.
- The rustc and cargo versions are printed by `configure` before compilation.
- Authors and licences of all vendored crates are in `inst/AUTHORS` and
  referenced from the `Authors@R` and `Copyright` fields.

The tarball is 8.4 MB, almost all of it the vendored crates (`vendor.tar.xz`
is 8.2 MB after dropping crates that only compile on platforms CRAN does not
build for).

## R CMD check results

0 errors | 0 warnings | 1 note

- New submission.
- Possibly misspelled words in DESCRIPTION: Malkov, Yashunin and Charikar are
  author names; HNSW, NNDescent, NN-Descent and Vamana are method names.

The installed size is 11.8 MB, of which `libs` is 10.7 MB: the statically
linked Rust library.
