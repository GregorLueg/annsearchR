# Getting started with annsearchR

annsearchR gives R the CPU indices of the Rust crate
[ann-search-rs](https://github.com/GregorLueg/ann-search-rs). You build
an index once, it lives in Rust memory behind an R6 object, and you
query it as often as you like. Thirteen index types share one interface,
so swapping HNSW for IVF is a one-word change.

``` r

library(annsearchR)
```

## Build and query

We need some data.
[`generate_clustered_data()`](https://gregorlueg.github.io/annsearchR/reference/generate_clustered_data.md)
is the same Gaussian cluster generator the Rust crate uses for its own
benchmarks. We hold back a few rows as queries.

``` r

dat <- generate_clustered_data(20000L, 32L, n_clusters = 20L, seed = 42L)$data
query <- dat[1:500, ]
train <- dat[-(1:500), ]
```

Build an HNSW index and ask for the 10 nearest neighbours of each query:

``` r

hnsw <- HnswIndex$new(train, metric = "euclidean")
hnsw
#> <HnswIndex> 19500 x 32 | metric: euclidean | precision: float | ef_search = 50

res <- hnsw$predict(query, k = 10L)
str(res)
#> List of 2
#>  $ idx : int [1:500, 1:10] 15000 19181 5839 9065 6499 6382 18092 18128 18693 13024 ...
#>  $ dist: num [1:500, 1:10] 7.9 3.18 7.58 5.47 8.01 ...
```

`idx` holds 1-based row indices into `train`, `dist` the distances. Both
are queries x k matrices. Euclidean comes back as true Euclidean
distance; use `metric = "sqeuclidean"` if you want the squared version
and save the square root. Don’t need the distances?
`return_dist = FALSE` skips them.

Prefer functions over methods?
[`predict()`](https://rdrr.io/r/stats/predict.html) works too:

``` r

identical(predict(hnsw, query, k = 10L), res)
#> [1] TRUE
```

## Is it right? Measure recall

Approximate means approximate. `ExhaustiveIndex` compares every query to
every point, so it gives the exact answer, and
[`knn_recall()`](https://gregorlueg.github.io/annsearchR/reference/knn_recall.md)
tells you what fraction of the true neighbours the approximate index
found.

``` r

truth <- ExhaustiveIndex$new(train)$predict(query, k = 10L)$idx
knn_recall(truth, res$idx)
#> [1] 0.9854
```

Brute force is no slouch here either: it is SIMD accelerated,
multi-threaded and, on macOS, runs large batches through Apple
Accelerate. Up to a few hundred thousand points it’s worth timing before
reaching for anything approximate.

## Tune at query time

Every approximate index has a search-time knob, exposed as a field you
can change after the build. For HNSW it’s `ef_search`, the width of the
beam that walks the graph. Wider beam, better recall, slower queries:

``` r

for (ef in c(10L, 20L, 50L, 100L)) {
  hnsw$ef_search <- ef
  t <- system.time(r <- hnsw$predict(query, k = 10L))[["elapsed"]]
  cat(sprintf(
    "ef_search = %3d   recall %.3f   %.3fs\n",
    ef,
    knn_recall(truth, r$idx),
    t
  ))
}
#> ef_search =  10   recall 0.848   0.003s
#> ef_search =  20   recall 0.938   0.003s
#> ef_search =  50   recall 0.985   0.006s
#> ef_search = 100   recall 0.995   0.010s
```

The knobs per index:

| Index                                        | Knob(s)                     |
|----------------------------------------------|-----------------------------|
| `HnswIndex`                                  | `ef_search`                 |
| `NNDescentIndex`, `VamanaIndex`, `NsgIndex`  | `ef_search`                 |
| `RnnDescentIndex`                            | `ef_search`, `k_search`     |
| `AnnoyIndex`, `KdTreeIndex`, `BallTreeIndex` | `search_budget`             |
| `IvfIndex`, `SoarIndex`                      | `nprobe`                    |
| `LshIndex`                                   | `n_probe`, `max_candidates` |

`NULL` lets the Rust crate pick its own default. Build-time parameters
(graph degree, number of trees, number of cells) are constructor
arguments and need a rebuild.

## Which index?

``` r

indices <- list(
  exhaustive = ExhaustiveIndex,
  kmknn = KmknnIndex,
  annoy = AnnoyIndex,
  kdtree = KdTreeIndex,
  balltree = BallTreeIndex,
  hnsw = HnswIndex,
  ivf = IvfIndex,
  soar = SoarIndex,
  lsh = LshIndex,
  nndescent = NNDescentIndex,
  vamana = VamanaIndex,
  nsg = NsgIndex,
  rnndescent = RnnDescentIndex
)

comparison <- do.call(
  rbind,
  lapply(names(indices), \(nm) {
    t_build <- system.time(idx <- indices[[nm]]$new(train))[["elapsed"]]
    t_query <- system.time(r <- idx$predict(query, k = 10L))[["elapsed"]]
    data.frame(
      index = nm,
      build_s = t_build,
      query_s = t_query,
      recall = round(knn_recall(truth, r$idx), 3)
    )
  })
)
comparison
#>         index build_s query_s recall
#> 1  exhaustive   0.003   0.019  1.000
#> 2       kmknn   0.138   0.004  1.000
#> 3       annoy   0.053   0.014  1.000
#> 4      kdtree   0.071   0.011  0.999
#> 5    balltree   0.020   0.004  0.932
#> 6        hnsw   0.564   0.006  0.986
#> 7         ivf   0.136   0.003  0.995
#> 8        soar   0.149   0.009  0.999
#> 9         lsh   0.009   0.007  0.973
#> 10  nndescent   0.381   0.005  0.884
#> 11     vamana   1.219   0.012  0.999
#> 12        nsg   5.545   0.014  0.999
#> 13 rnndescent   0.438   0.011  0.989
```

These are default settings on small, easy data with two threads, so read
the table for the shape of things, not as a benchmark. For that, see the
[benchmarks
article](https://gregorlueg.github.io/annsearchR/articles/benchmarks.html),
which compares annsearchR against RcppHNSW, RcppAnnoy, BiocNeighbors,
rnndescent, FNN and RANN at equal recall on Fashion-MNIST and SIFT.

What each family does:

- **Exact:** `ExhaustiveIndex` scores every point. `KmknnIndex` prunes
  whole k-means clusters by the triangle inequality, with the same
  answers. On Fashion-MNIST and SIFT brute force won, so time both on
  your data.
- **Graphs:** `HnswIndex`, `VamanaIndex`, `NsgIndex` and
  `RnnDescentIndex` build a navigable neighbour graph and walk it.
  `NNDescentIndex` builds the kNN graph directly, which makes it the one
  to use when you want the graph of the data itself (see below). In the
  benchmarks HNSW had the best recall per query time.
- **Partitions:** `IvfIndex` cuts the space into k-means cells and
  searches the closest `nprobe` of them. `SoarIndex` adds a second cell
  per point. `LshIndex` buckets points by random projections.
- **Trees:** `AnnoyIndex` and `KdTreeIndex` are forests of random
  splits. `BallTreeIndex` is a metric tree whose default `search_budget`
  (5% of the points) is approximate; raise it for recall.

## The kNN graph of the data itself

UMAP, clustering, graph diffusion: often you want the neighbours of
every point in the index, not of new queries. `$query_self()` does that
through each index’s own fast path, and counts each point as its own
first neighbour:

``` r

knn <- hnsw$query_self(k = 15L)
dim(knn$idx)
#> [1] 19500    15
all(knn$idx[, 1] == seq_len(nrow(train)))
#> [1] FALSE
```

`NNDescentIndex` goes one better. NN-Descent builds the kNN graph
directly, so `$extract_knn()` hands it back without any search at all:

``` r

nnd <- NNDescentIndex$new(train, k_graph = 15L)
graph <- nnd$extract_knn()

truth_self <- ExhaustiveIndex$new(train)$query_self(k = 15L)$idx
knn_recall(truth_self, graph$idx)
#> [1] 0.9991829
```

Leave `diversify_prob` at 0 if extraction is the point: pruning edges
makes a better search graph and a worse kNN graph.

## Metrics and precision

Four metrics: `"euclidean"`, `"sqeuclidean"`, `"cosine"` (returned as
`1 - cosine similarity`) and `"manhattan"`. Annoy, BallTree, KMKNN, IVF,
SOAR and LSH don’t support Manhattan, and say so:

``` r

AnnoyIndex$new(train, metric = "manhattan")
#> Error in `match.arg()`:
#> ! 'arg' should be one of "euclidean", "sqeuclidean", "cosine"
```

Data is stored as 32-bit floats by default, which halves the memory
against R’s doubles. `precision = "double"` keeps 64 bits if you need
them:

``` r

hnsw64 <- HnswIndex$new(train, precision = "double")
hnsw64$precision
#> [1] "double"
```

## Threads

Builds and queries are parallel over all cores by default.
[`ann_set_threads()`](https://gregorlueg.github.io/annsearchR/reference/ann_set_threads.md)
installs a dedicated pool and can be called as often as you like:

``` r

old <- ann_set_threads(1L)
ann_get_threads()
#> [1] 1
ann_set_threads(0L) # back to all cores
```

HNSW inserts nodes in parallel, so two multi-threaded builds with the
same seed give slightly different graphs. Need bit-identical results?
Build on one thread.

## Saving and loading

The index lives in Rust memory, so
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) can’t see it. A
restored object holds a dead pointer and tells you so instead of
crashing:

``` r

restored <- unserialize(serialize(hnsw, NULL))
restored$predict(query, k = 10L)
#> Error in `private$check_ptr()`:
#> ! The index pointer is dead, most likely because the object went through saveRDS()/readRDS(). Use `$save()` and `load_ann_index()`.
```

Use `$save()` and
[`load_ann_index()`](https://gregorlueg.github.io/annsearchR/reference/load_ann_index.md)
instead. The search knobs and metric travel with the index:

``` r

dir <- tempfile()
hnsw$ef_search <- 80L
hnsw$save(dir)

loaded <- load_ann_index(dir)
loaded
#> <HnswIndex> 19500 x 32 | metric: euclidean | precision: float | ef_search = 80
identical(loaded$predict(query, k = 10L), hnsw$predict(query, k = 10L))
#> [1] TRUE
```
