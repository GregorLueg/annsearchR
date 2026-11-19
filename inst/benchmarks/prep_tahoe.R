# Build the Tahoe single cell datasets in the ann-benchmarks HDF5 layout.
#
# Usage: Rscript inst/benchmarks/prep_tahoe.R <pca.qs2> [out_dir]
#
# Input: a cells x 32 PCA matrix of one Tahoe-100M plate (2,857,393 cells).
# Output: tahoe-{100k,500k,1m}-32-euclidean.hdf5, each
# with 10,000 held-out query cells and the exact 100 nearest neighbours from
# annsearchR's ExhaustiveIndex. Stored as float32, cell barcodes dropped.

args <- commandArgs(trailingOnly = TRUE)
in_path <- args[1]
out_dir <- if (length(args) >= 2) args[2] else "."

n_query <- 10000L
n_truth <- 100L

pca <- qs2::qs_read(in_path)
dimnames(pca) <- NULL

set.seed(42L)
perm <- sample.int(nrow(pca))
test <- pca[perm[seq_len(n_query)], ]

write_h5 <- function(n_train, name) {
  train <- pca[perm[n_query + seq_len(n_train)], ]
  truth <- annsearchR::ExhaustiveIndex$new(train, precision = "double")$predict(
    test,
    k = n_truth,
    return_dist = TRUE
  )

  path <- file.path(out_dir, paste0(name, ".hdf5"))
  if (file.exists(path)) {
    file.remove(path)
  }
  f <- hdf5r::H5File$new(path, "w")
  on.exit(f$close_all())
  f32 <- hdf5r::h5types$H5T_IEEE_F32LE
  # hdf5r writes R's column-major arrays transposed, so features x samples
  # here reads back as samples x features in h5py
  f$create_dataset("train", t(train), dtype = f32, gzip_level = 4)
  f$create_dataset("test", t(test), dtype = f32, gzip_level = 4)
  f$create_dataset("neighbors", t(truth$idx - 1L), gzip_level = 4)
  f$create_dataset("distances", t(truth$dist), dtype = f32, gzip_level = 4)
  hdf5r::h5attr(f, "distance") <- "euclidean"
  cat(sprintf("wrote %s: %d x %d\n", path, nrow(train), ncol(train)))
}

write_h5(100000L, "tahoe-100k-32-euclidean")
write_h5(500000L, "tahoe-500k-32-euclidean")
write_h5(1000000L, "tahoe-1m-32-euclidean")
