#!/usr/bin/env sh
# Writes src/rust/vendor.tar.xz for a CRAN tarball. Run before R CMD build.
# The tarball stays out of git. Needs `cargo install cargo-vendor-filterer`.
#
# Plain `cargo vendor` takes every target and every cfg, which pulls in
# criterion, plotters and web-sys via rdst's cfg(bench) deps and every
# windows-* import lib. Filtering to the CRAN platforms halves the tarball.
set -eu

cd "$(dirname "$0")/../src/rust"
rm -rf vendor vendor.tar.xz

cargo vendor-filterer \
  --platform=x86_64-unknown-linux-gnu \
  --platform=aarch64-unknown-linux-gnu \
  --platform=x86_64-apple-darwin \
  --platform=aarch64-apple-darwin \
  --platform=x86_64-pc-windows-gnu \
  --platform=aarch64-pc-windows-gnullvm \
  --exclude-crate-path='*#tests' \
  --exclude-crate-path='*#benches' \
  --exclude-crate-path='*#examples' \
  --exclude-crate-path='*#docs' \
  vendor > /dev/null

tar -cJ --no-xattrs -f vendor.tar.xz vendor
rm -rf vendor
ls -lh vendor.tar.xz
