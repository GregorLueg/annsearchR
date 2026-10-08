# Benchmark annsearchR against the kNN packages R users actually reach for.
#
# Usage: Rscript inst/benchmarks/bench_synthetic.R [n] [dim] [n_query] [k]
#
# Build parameters are matched where the libraries expose them: HNSW at
# M = 16, ef_construction = 200, ef_search = 50; Annoy at 50 trees with a
# search budget of 1500 items per query. Ground truth comes from
# annsearchR's ExhaustiveIndex (checked against FNN, which is exact).
# FNN, RANN and RcppAnnoy are single-threaded; the others run at 1 thread and
# at all cores.

# setup ------------------------------------------------------------------------

args <- as.integer(commandArgs(trailingOnly = TRUE))
n <- if (length(args) >= 1) args[1] else 50000L
dim <- if (length(args) >= 2) args[2] else 32L
n_query <- if (length(args) >= 3) args[3] else 5000L
k <- if (length(args) >= 4) args[4] else 15L

n_cores <- parallel::detectCores(logical = FALSE)
hnsw_m <- 16L
hnsw_efc <- 200L
hnsw_ef <- 50L
annoy_trees <- 50L
annoy_search_k <- 1500L

dat <- annsearchR::generate_clustered_data(n, dim, seed = 42L)$data
query <- annsearchR::generate_clustered_data(n_query, dim, seed = 123L)$data

cat(sprintf(
  "n = %d, dim = %d, queries = %d, k = %d, cores = %d\n",
  n,
  dim,
  n_query,
  k,
  n_cores
))

# helpers ----------------------------------------------------------------------

elapsed <- function(expr) {
  system.time(expr)[["elapsed"]]
}

# One benchmark row. `build` returns the index (or NULL for libraries without
# a separate build); `query` takes it and returns the n_query x k index matrix.
run_case <- function(library, method, threads, build, query) {
  gc(verbose = FALSE)
  index <- NULL
  t_build <- elapsed(index <- build())
  res <- NULL
  t_query <- elapsed(res <- query(index))
  data.table::data.table(
    library = library,
    method = method,
    threads = threads,
    build_s = t_build,
    query_s = t_query,
    recall = annsearchR::knn_recall(truth, res)
  )
}

# ground truth -----------------------------------------------------------------

t_truth <- elapsed(
  truth <- annsearchR::ExhaustiveIndex$new(dat)$predict(query, k = k)$idx
)
cat(sprintf("ground truth (exhaustive, all cores): %.2fs\n", t_truth))

# annsearchR -------------------------------------------------------------------

annsearchr_cases <- function(threads) {
  annsearchR::ann_set_threads(threads)
  on.exit(annsearchR::ann_set_threads(0L))
  list(
    run_case(
      "annsearchR",
      "exhaustive",
      threads,
      \() annsearchR::ExhaustiveIndex$new(dat),
      \(idx) idx$predict(query, k = k, return_dist = FALSE)$idx
    ),
    run_case(
      "annsearchR",
      "hnsw",
      threads,
      \() {
        annsearchR::HnswIndex$new(
          dat,
          m = hnsw_m,
          ef_construction = hnsw_efc,
          ef_search = hnsw_ef
        )
      },
      \(idx) idx$predict(query, k = k, return_dist = FALSE)$idx
    ),
    run_case(
      "annsearchR",
      "annoy",
      threads,
      \() {
        annsearchR::AnnoyIndex$new(
          dat,
          n_trees = annoy_trees,
          search_budget = annoy_search_k
        )
      },
      \(idx) idx$predict(query, k = k, return_dist = FALSE)$idx
    )
  )
}

# RcppHNSW ---------------------------------------------------------------------

rcpphnsw_case <- function(threads) {
  # RcppHNSW: n_threads = 0 means no worker threads
  nt <- if (threads == 1L) 0L else threads
  run_case(
    "RcppHNSW",
    "hnsw",
    threads,
    \() {
      RcppHNSW::hnsw_build(
        dat,
        distance = "euclidean",
        M = hnsw_m,
        ef = hnsw_efc,
        n_threads = nt,
        progress = "none"
      )
    },
    \(idx) {
      RcppHNSW::hnsw_search(
        query,
        idx,
        k = k,
        ef = hnsw_ef,
        n_threads = nt,
        progress = "none"
      )$idx
    }
  )
}

# RcppAnnoy --------------------------------------------------------------------

rcppannoy_case <- function() {
  run_case(
    "RcppAnnoy",
    "annoy",
    1L,
    \() {
      a <- methods::new(RcppAnnoy::AnnoyEuclidean, dim)
      a$setSeed(42L)
      for (i in seq_len(n)) {
        a$addItem(i - 1L, dat[i, ])
      }
      a$build(annoy_trees)
      a
    },
    \(a) {
      res <- matrix(NA_integer_, n_query, k)
      for (i in seq_len(n_query)) {
        res[i, ] <- a$getNNsByVectorList(
          query[i, ],
          k,
          annoy_search_k,
          FALSE
        )$item +
          1L
      }
      res
    }
  )
}

# BiocNeighbors ----------------------------------------------------------------

biocneighbors_cases <- function(threads) {
  params <- list(
    kmknn = BiocNeighbors::KmknnParam(),
    hnsw = BiocNeighbors::HnswParam(
      nlinks = hnsw_m,
      ef.construction = hnsw_efc,
      ef.search = hnsw_ef
    ),
    annoy = BiocNeighbors::AnnoyParam(
      ntrees = annoy_trees,
      search.mult = annoy_search_k / k
    )
  )
  lapply(names(params), \(nm) {
    run_case(
      "BiocNeighbors",
      nm,
      threads,
      \() BiocNeighbors::buildIndex(dat, BNPARAM = params[[nm]]),
      \(idx) {
        BiocNeighbors::queryKNN(
          idx,
          query,
          k = k,
          get.distance = FALSE,
          num.threads = threads
        )$index
      }
    )
  })
}

# FNN / RANN -------------------------------------------------------------------

exact_tree_cases <- function() {
  list(
    run_case(
      "FNN",
      "kd_tree",
      1L,
      \() NULL,
      \(idx) FNN::get.knnx(dat, query, k = k, algorithm = "kd_tree")$nn.index
    ),
    run_case(
      "RANN",
      "kd_tree",
      1L,
      \() NULL,
      \(idx) RANN::nn2(dat, query, k = k)$nn.idx
    )
  )
}

# run --------------------------------------------------------------------------

results <- data.table::rbindlist(c(
  annsearchr_cases(1L),
  annsearchr_cases(n_cores),
  list(rcpphnsw_case(1L), rcpphnsw_case(n_cores)),
  list(rcppannoy_case()),
  biocneighbors_cases(1L),
  biocneighbors_cases(n_cores),
  exact_tree_cases()
))
results[, total_s := build_s + query_s]
data.table::setorder(results, method, threads, total_s)

print(results, digits = 3)

out_dir <- file.path("inst", "benchmarks", "results")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
data.table::fwrite(
  results,
  file.path(
    out_dir,
    sprintf("synthetic_n%d_d%d_q%d_k%d.csv", n, dim, n_query, k)
  )
)
