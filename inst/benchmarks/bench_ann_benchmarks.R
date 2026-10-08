# Recall vs speed sweep on the ann-benchmarks datasets.
#
# Usage: Rscript inst/benchmarks/bench_ann_benchmarks.R [dataset] [threads]
#
# dataset: fashion-mnist-784-euclidean (default) or sift-128-euclidean.
# Downloaded once to tools::R_user_dir("annsearchR", "cache").
#
# One build per library at matched parameters (HNSW M = 16,
# ef_construction = 200; Annoy 50 trees), then the search-time knob is swept.
# Compare libraries at equal recall, not at equal settings: the summary gives
# the best queries per second each library reaches at recall >= 0.9 / 0.95 /
# 0.99. FNN and RANN are single-threaded whatever `threads` says. RcppAnnoy
# builds single-threaded; with threads > 1 its queries are forked over chunks
# via parallel::mclapply (not available on Windows), fork cost included.
# FNN and RANN are exact kd-trees and run on a query subset; QPS normalises.
# BiocNeighbors bakes the search knob into the prebuilt index, so its HNSW and
# Annoy get one matched point each rather than a sweep.

# setup ------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
dataset <- if (length(args) >= 1) args[1] else "fashion-mnist-784-euclidean"
threads <- if (length(args) >= 2) as.integer(args[2]) else 1L
checkmate::assertChoice(
  dataset,
  c("fashion-mnist-784-euclidean", "sift-128-euclidean")
)

k <- 10L
n_exact_tree_queries <- 1000L
hnsw_m <- 16L
hnsw_efc <- 200L
ef_grid <- c(10L, 20L, 40L, 80L, 160L, 320L, 640L)
annoy_trees <- 50L
search_k_grid <- k * annoy_trees * c(1L, 2L, 5L, 10L, 20L, 50L, 100L)
nprobe_grid <- c(2L, 4L, 8L, 16L, 32L, 64L, 128L)
nndescent_k_graph <- 30L
epsilon_grid <- c(0, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3)

# data -------------------------------------------------------------------------

load_dataset <- function(name) {
  cache <- file.path(tools::R_user_dir("annsearchR", "cache"), "ann-benchmarks")
  dir.create(cache, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(cache, paste0(name, ".hdf5"))
  if (!file.exists(path)) {
    options(timeout = max(3600, getOption("timeout")))
    utils::download.file(
      sprintf("http://ann-benchmarks.com/%s.hdf5", name),
      path,
      mode = "wb"
    )
  }
  f <- hdf5r::H5File$new(path, "r")
  on.exit(f$close_all())
  # hdf5r returns features x samples and 0-based neighbour indices
  list(
    train = t(f[["train"]][,]),
    test = t(f[["test"]][,]),
    truth = t(f[["neighbors"]][,])[, seq_len(k)] + 1L
  )
}

ds <- load_dataset(dataset)
n_query <- nrow(ds$test)
cat(sprintf(
  "%s: train %d x %d, queries %d, k = %d, threads = %d\n",
  dataset,
  nrow(ds$train),
  ncol(ds$train),
  n_query,
  k,
  threads
))

# helpers ----------------------------------------------------------------------

elapsed <- function(expr) {
  system.time(expr)[["elapsed"]]
}

timed_build <- function(label, expr) {
  gc(verbose = FALSE)
  t <- elapsed(index <- expr)
  cat(sprintf("  built %-26s %8.2fs\n", label, t))
  list(index = index, build_s = t)
}

# One sweep point. `query` returns the query x k index matrix for `rows`.
sweep_point <- function(library, method, build_s, param, query, rows) {
  t <- elapsed(res <- query())
  data.table::data.table(
    library = library,
    method = method,
    threads_query = if (library %in% c("RcppAnnoy", "FNN", "RANN")) {
      1L
    } else {
      threads
    },
    build_s = build_s,
    param = param,
    query_s = t,
    qps = length(rows) / t,
    recall = annsearchR::knn_recall(ds$truth[rows, , drop = FALSE], res)
  )
}

all_rows <- seq_len(n_query)
annsearchR::ann_set_threads(threads)
rcpphnsw_threads <- if (threads == 1L) 0L else threads

# exact ------------------------------------------------------------------------

cat("exact\n")
b <- timed_build(
  "annsearchR exhaustive",
  annsearchR::ExhaustiveIndex$new(ds$train)
)
exact <- list(
  sweep_point(
    "annsearchR",
    "exhaustive",
    b$build_s,
    "-",
    \() b$index$predict(ds$test, k = k, return_dist = FALSE)$idx,
    all_rows
  )
)
cat(sprintf(
  "  sanity: exhaustive recall vs file truth = %.4f\n",
  exact[[1]]$recall
))

b <- timed_build("annsearchR kmknn", annsearchR::KmknnIndex$new(ds$train))
exact[[length(exact) + 1L]] <- sweep_point(
  "annsearchR",
  "kmknn",
  b$build_s,
  "-",
  \() b$index$predict(ds$test, k = k, return_dist = FALSE)$idx,
  all_rows
)

b <- timed_build(
  "BiocNeighbors kmknn",
  BiocNeighbors::buildIndex(ds$train, BNPARAM = BiocNeighbors::KmknnParam())
)
exact[[length(exact) + 1L]] <- sweep_point(
  "BiocNeighbors",
  "kmknn",
  b$build_s,
  "-",
  \() {
    BiocNeighbors::queryKNN(
      b$index,
      ds$test,
      k = k,
      get.distance = FALSE,
      num.threads = threads
    )$index
  },
  all_rows
)

sub_rows <- seq_len(n_exact_tree_queries)
exact[[length(exact) + 1L]] <- sweep_point(
  "FNN",
  "kd_tree",
  0,
  "-",
  \() {
    FNN::get.knnx(
      ds$train,
      ds$test[sub_rows, ],
      k = k,
      algorithm = "kd_tree"
    )$nn.index
  },
  sub_rows
)
exact[[length(exact) + 1L]] <- sweep_point(
  "RANN",
  "kd_tree",
  0,
  "-",
  \() RANN::nn2(ds$train, ds$test[sub_rows, ], k = k)$nn.idx,
  sub_rows
)

# hnsw -------------------------------------------------------------------------

cat("hnsw\n")
b <- timed_build(
  "annsearchR hnsw",
  annsearchR::HnswIndex$new(
    ds$train,
    m = hnsw_m,
    ef_construction = hnsw_efc
  )
)
hnsw <- lapply(ef_grid, \(ef) {
  b$index$ef_search <- ef
  sweep_point(
    "annsearchR",
    "hnsw",
    b$build_s,
    sprintf("ef=%d", ef),
    \() b$index$predict(ds$test, k = k, return_dist = FALSE)$idx,
    all_rows
  )
})

b <- timed_build(
  "RcppHNSW hnsw",
  RcppHNSW::hnsw_build(
    ds$train,
    distance = "euclidean",
    M = hnsw_m,
    ef = hnsw_efc,
    n_threads = rcpphnsw_threads,
    progress = "none"
  )
)
hnsw <- c(
  hnsw,
  lapply(ef_grid, \(ef) {
    sweep_point(
      "RcppHNSW",
      "hnsw",
      b$build_s,
      sprintf("ef=%d", ef),
      \() {
        RcppHNSW::hnsw_search(
          ds$test,
          b$index,
          k = k,
          ef = ef,
          n_threads = rcpphnsw_threads,
          progress = "none"
        )$idx
      },
      all_rows
    )
  })
)

bioc_ef <- 80L
b <- timed_build(
  "BiocNeighbors hnsw",
  BiocNeighbors::buildIndex(
    ds$train,
    BNPARAM = BiocNeighbors::HnswParam(
      nlinks = hnsw_m,
      ef.construction = hnsw_efc,
      ef.search = bioc_ef
    )
  )
)
hnsw[[length(hnsw) + 1L]] <- sweep_point(
  "BiocNeighbors",
  "hnsw",
  b$build_s,
  sprintf("ef=%d", bioc_ef),
  \() {
    BiocNeighbors::queryKNN(
      b$index,
      ds$test,
      k = k,
      get.distance = FALSE,
      num.threads = threads
    )$index
  },
  all_rows
)

# annoy ------------------------------------------------------------------------

cat("annoy\n")
b <- timed_build(
  "annsearchR annoy",
  annsearchR::AnnoyIndex$new(ds$train, n_trees = annoy_trees)
)
annoy <- lapply(search_k_grid, \(sk) {
  b$index$search_budget <- sk
  sweep_point(
    "annsearchR",
    "annoy",
    b$build_s,
    sprintf("search_k=%d", sk),
    \() b$index$predict(ds$test, k = k, return_dist = FALSE)$idx,
    all_rows
  )
})

b <- timed_build("RcppAnnoy annoy", {
  a <- methods::new(RcppAnnoy::AnnoyEuclidean, ncol(ds$train))
  a$setSeed(42L)
  for (i in seq_len(nrow(ds$train))) {
    a$addItem(i - 1L, ds$train[i, ])
  }
  a$build(annoy_trees)
  a
})
rcppannoy_query <- function(rows, sk) {
  res <- matrix(NA_integer_, length(rows), k)
  for (j in seq_along(rows)) {
    res[j, ] <- b$index$getNNsByVectorList(
      ds$test[rows[j], ],
      k,
      sk,
      FALSE
    )$item +
      1L
  }
  res
}
# RcppAnnoy has no threaded or batch query; the only route to more cores from
# R is forking over query chunks. Forks inherit the built index.
rcppannoy_label <- if (threads > 1L) "RcppAnnoy (fork)" else "RcppAnnoy"
query_chunks <- parallel::splitIndices(n_query, threads)
annoy <- c(
  annoy,
  lapply(search_k_grid, \(sk) {
    sweep_point(
      rcppannoy_label,
      "annoy",
      b$build_s,
      sprintf("search_k=%d", sk),
      \() {
        if (threads == 1L) {
          return(rcppannoy_query(all_rows, sk))
        }
        do.call(
          rbind,
          parallel::mclapply(
            query_chunks,
            rcppannoy_query,
            sk = sk,
            mc.cores = threads
          )
        )
      },
      all_rows
    )
  })
)

bioc_sk <- k * annoy_trees * 10L
b <- timed_build(
  "BiocNeighbors annoy",
  BiocNeighbors::buildIndex(
    ds$train,
    BNPARAM = BiocNeighbors::AnnoyParam(
      ntrees = annoy_trees,
      search.mult = bioc_sk / k
    )
  )
)
annoy[[length(annoy) + 1L]] <- sweep_point(
  "BiocNeighbors",
  "annoy",
  b$build_s,
  sprintf("search_k=%d", bioc_sk),
  \() {
    BiocNeighbors::queryKNN(
      b$index,
      ds$test,
      k = k,
      get.distance = FALSE,
      num.threads = threads
    )$index
  },
  all_rows
)

# ivf --------------------------------------------------------------------------

# No R package ships IVF, so it only sits on the same recall targets.
cat("ivf\n")
b <- timed_build("annsearchR ivf", annsearchR::IvfIndex$new(ds$train))
ivf <- lapply(nprobe_grid, \(np) {
  b$index$nprobe <- np
  sweep_point(
    "annsearchR",
    "ivf",
    b$build_s,
    sprintf("nprobe=%d", np),
    \() b$index$predict(ds$test, k = k, return_dist = FALSE)$idx,
    all_rows
  )
})

# nndescent --------------------------------------------------------------------

# Both build a k = 30 graph. rnndescent sweeps epsilon (search tolerance)
# where annsearchR sweeps ef_search; equal recall is the common ground.
cat("nndescent\n")
b <- timed_build(
  "annsearchR nndescent",
  annsearchR::NNDescentIndex$new(ds$train, k_graph = nndescent_k_graph)
)
nndescent <- lapply(ef_grid, \(ef) {
  b$index$ef_search <- ef
  sweep_point(
    "annsearchR",
    "nndescent",
    b$build_s,
    sprintf("ef=%d", ef),
    \() b$index$predict(ds$test, k = k, return_dist = FALSE)$idx,
    all_rows
  )
})

# rnndescent: n_threads = 0 runs serially
rnndescent_threads <- if (threads == 1L) 0L else threads
b <- timed_build(
  "rnndescent nndescent",
  rnndescent::rnnd_build(
    ds$train,
    k = nndescent_k_graph,
    metric = "euclidean",
    n_threads = rnndescent_threads
  )
)
nndescent <- c(
  nndescent,
  lapply(epsilon_grid, \(eps) {
    sweep_point(
      "rnndescent",
      "nndescent",
      b$build_s,
      sprintf("epsilon=%.2f", eps),
      \() {
        rnndescent::rnnd_query(
          b$index,
          ds$test,
          k = k,
          epsilon = eps,
          n_threads = rnndescent_threads
        )$idx
      },
      all_rows
    )
  })
)

annsearchR::ann_set_threads(0L)

# results ----------------------------------------------------------------------

sweep <- data.table::rbindlist(c(exact, hnsw, annoy, ivf, nndescent))

# Best QPS each library reaches at or above each recall target. NA: never got
# there on this grid.
summary <- data.table::rbindlist(lapply(c(0.9, 0.95, 0.99), \(thr) {
  sweep[,
    .(
      build_s = build_s[1],
      target = thr,
      qps = if (any(recall >= thr)) max(qps[recall >= thr]) else NA_real_
    ),
    by = .(library, method)
  ]
}))
summary <- data.table::dcast(
  summary,
  method + library + build_s ~ paste0("qps@", target),
  value.var = "qps"
)

cat("\nsweep\n")
print(
  sweep[, .(
    library,
    method,
    param,
    qps = round(qps),
    recall = round(recall, 4)
  )],
  nrows = 200
)
cat("\nbest QPS at recall target\n")
print(summary, digits = 3)

out_dir <- file.path("inst", "benchmarks", "results")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
stem <- file.path(out_dir, sprintf("%s_t%d", dataset, threads))
data.table::fwrite(sweep, paste0(stem, "_sweep.csv"))
data.table::fwrite(summary, paste0(stem, "_summary.csv"))
