# Time to the full kNN graph on the Tahoe single cell data.
#
# Usage: Rscript inst/benchmarks/bench_knn_graph.R [dataset] [threads]
#
# dataset: tahoe-100k-32-euclidean, tahoe-500k-32-euclidean (default) or
# tahoe-1m-32-euclidean, from the cache bench_ann_benchmarks.R fills.
#
# What FindNeighbors() and friends need: the k = 15 graph over every cell,
# the cell itself included. Each point is build plus self-query, from the raw
# matrix to the finished graph. Every index builds once and its search knob is
# swept; NN-Descent reads the graph straight off the descent instead. Recall is
# taken on 10,000 random cells against KMKNN's exact graph. The summary gives
# the shortest time each method needs to reach recall 0.9 / 0.95 / 0.99.
# RcppAnnoy builds single-threaded and is queried the way Seurat does it
# (annoy_search.cpp), save cost included; search_k = 750 is Seurat's default.

# setup ------------------------------------------------------------------------

options(width = 160)
args <- commandArgs(trailingOnly = TRUE)
dataset <- if (length(args) >= 1) args[1] else "tahoe-500k-32-euclidean"
threads <- if (length(args) >= 2) as.integer(args[2]) else 10L
checkmate::assertChoice(
  dataset,
  c(
    "tahoe-100k-32-euclidean",
    "tahoe-500k-32-euclidean",
    "tahoe-1m-32-euclidean"
  )
)

k <- 15L
n_recall <- 10000L
hnsw_m <- 16L
hnsw_efc <- 200L
ef_grid <- c(15L, 20L, 40L, 80L, 160L)
annoy_trees <- 50L
search_k_grid <- k * annoy_trees * c(1L, 2L, 5L, 10L)
nprobe_grid <- c(2L, 4L, 8L, 16L, 32L)
k_graph_grid <- c(15L, 20L, 30L)

path <- file.path(
  tools::R_user_dir("annsearchR", "cache"),
  "ann-benchmarks",
  paste0(dataset, ".hdf5")
)
f <- hdf5r::H5File$new(path, "r")
x <- t(f[["train"]][,])
f$close_all()
n <- nrow(x)
cat(sprintf("%s: %d x %d, k = %d, threads = %d\n", dataset, n, ncol(x), k, threads))

annsearchR::ann_set_threads(threads)
Rcpp::sourceCpp(file.path("inst", "benchmarks", "annoy_search.cpp"))

# helpers ----------------------------------------------------------------------

elapsed <- function(expr) {
  system.time(expr)[["elapsed"]]
}

set.seed(42L)
rows <- sort(sample.int(n, n_recall))

timed_build <- function(label, expr) {
  gc(verbose = FALSE)
  t <- elapsed(index <- expr)
  cat(sprintf("  built %-26s %8.2fs\n", label, t))
  list(index = index, build_s = t)
}

# `graph` returns the n x k index matrix.
graph_point <- function(library, method, build_s, param, graph) {
  t <- elapsed(res <- graph())
  out <- data.table::data.table(
    library = library,
    method = method,
    param = param,
    build_s = build_s,
    query_s = t,
    total_s = build_s + t,
    recall = annsearchR::knn_recall(truth, res[rows, seq_len(k), drop = FALSE])
  )
  cat(sprintf(
    "  %-22s %-10s %-14s %7.2fs recall %.4f\n",
    library,
    method,
    param,
    out$total_s,
    out$recall
  ))
  out
}

# exact ------------------------------------------------------------------------

cat("exact\n")
b <- timed_build("annsearchR kmknn", annsearchR::KmknnIndex$new(x))
t <- elapsed(
  exact_graph <- b$index$query_self(k = k, return_dist = FALSE)$idx
)
truth <- exact_graph[rows, , drop = FALSE]
res <- list(data.table::data.table(
  library = "annsearchR",
  method = "kmknn",
  param = "-",
  build_s = b$build_s,
  query_s = t,
  total_s = b$build_s + t,
  recall = 1
))
rm(exact_graph)

# annoy ------------------------------------------------------------------------

cat("annoy\n")
b <- timed_build(
  "RcppAnnoy annoy",
  {
    a <- methods::new(RcppAnnoy::AnnoyEuclidean, ncol(x))
    a$setSeed(42L)
    for (i in seq_len(n)) {
      a$addItem(i - 1L, x[i, ])
    }
    a$build(annoy_trees)
    a
  }
)
for (sk in search_k_grid) {
  res[[length(res) + 1L]] <- graph_point(
    "RcppAnnoy (threaded)",
    "annoy",
    b$build_s,
    sprintf("search_k=%d", sk),
    \() {
      p <- tempfile(fileext = ".ann")
      on.exit(unlink(p), add = TRUE)
      b$index$save(p)
      annoy_search_threaded(p, x, k, sk, threads)
    }
  )
}
rm(b)

b <- timed_build(
  "annsearchR annoy",
  annsearchR::AnnoyIndex$new(x, n_trees = annoy_trees)
)
for (sk in search_k_grid) {
  b$index$search_budget <- sk
  res[[length(res) + 1L]] <- graph_point(
    "annsearchR",
    "annoy",
    b$build_s,
    sprintf("search_k=%d", sk),
    \() b$index$query_self(k = k, return_dist = FALSE)$idx
  )
}

# hnsw -------------------------------------------------------------------------

cat("hnsw\n")
b <- timed_build(
  "annsearchR hnsw",
  annsearchR::HnswIndex$new(x, m = hnsw_m, ef_construction = hnsw_efc)
)
for (ef in ef_grid) {
  b$index$ef_search <- ef
  res[[length(res) + 1L]] <- graph_point(
    "annsearchR",
    "hnsw",
    b$build_s,
    sprintf("ef=%d", ef),
    \() b$index$query_self(k = k, return_dist = FALSE)$idx
  )
}

# ivf --------------------------------------------------------------------------

cat("ivf\n")
b <- timed_build("annsearchR ivf", annsearchR::IvfIndex$new(x))
for (np in nprobe_grid) {
  b$index$nprobe <- np
  res[[length(res) + 1L]] <- graph_point(
    "annsearchR",
    "ivf",
    b$build_s,
    sprintf("nprobe=%d", np),
    \() b$index$query_self(k = k, return_dist = FALSE)$idx
  )
}

# nndescent --------------------------------------------------------------------

# The graph comes out of the build, so there is no search knob: k_graph trades
# time for recall, trimmed back to k afterwards.
cat("nndescent\n")
for (kg in k_graph_grid) {
  b <- timed_build(
    sprintf("annsearchR nndescent k=%d", kg),
    annsearchR::NNDescentIndex$new(x, k_graph = kg)
  )
  res[[length(res) + 1L]] <- graph_point(
    "annsearchR",
    "nndescent index",
    b$build_s,
    sprintf("k_graph=%d", kg),
    \() b$index$extract_knn(k = k, return_dist = FALSE)$idx
  )
  rm(b)
  gc(verbose = FALSE)
  res[[length(res) + 1L]] <- graph_point(
    "annsearchR",
    "nndescent graph",
    0,
    sprintf("k_graph=%d", kg),
    \() annsearchR::knn_graph_nndescent(x, k_graph = kg, return_dist = FALSE)$idx
  )
}

annsearchR::ann_set_threads(0L)

# results ----------------------------------------------------------------------

sweep <- data.table::rbindlist(res)

summary <- data.table::rbindlist(lapply(c(0.9, 0.95, 0.99), \(thr) {
  sweep[,
    .(
      target = thr,
      total_s = if (any(recall >= thr)) min(total_s[recall >= thr]) else NA_real_
    ),
    by = .(library, method)
  ]
}))
summary <- data.table::dcast(
  summary,
  method + library ~ paste0("s@", target),
  value.var = "total_s"
)

cat("\nsweep\n")
print(sweep[, .(library, method, param, build_s, query_s, total_s, recall = round(recall, 4))], nrows = 200, digits = 3)
cat("\nseconds to the full graph at recall target\n")
print(summary, digits = 3)

out_dir <- file.path("inst", "benchmarks", "results")
stem <- file.path(out_dir, sprintf("%s_knn_graph_t%d", dataset, threads))
data.table::fwrite(sweep, paste0(stem, "_sweep.csv"))
data.table::fwrite(summary, paste0(stem, "_summary.csv"))
