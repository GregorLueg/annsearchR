// Threaded query of a saved RcppAnnoy Euclidean index, for the benchmarks.
// Cut down from Seurat's src/annoy_nn.cpp; the file-backed parallel search
// idea is from James Melville's uwot package.

// [[Rcpp::depends(RcppAnnoy, RcppThread)]]
#include <RcppAnnoy.h>
#include <RcppThread.h>

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <vector>

// [[Rcpp::export]]
Rcpp::IntegerMatrix annoy_search_threaded(std::string index_path,
                                          Rcpp::NumericMatrix query, int k,
                                          int search_k, int nthreads) {
  const int n = query.nrow(), f = query.ncol();
  Annoy::AnnoyIndex<int32_t, float, Annoy::Euclidean, Kiss64Random,
                    RcppAnnoyIndexThreadPolicy>
      index(f);
  char *error = NULL;
  if (!index.load(index_path.c_str(), false, &error)) {
    std::string msg = "Unable to load Annoy index";
    if (error != NULL) {
      msg += ": ";
      msg += error;
      std::free(error);
    }
    Rcpp::stop(msg);
  }

  // Annoy wants row-major float queries; R matrices are column-major doubles.
  std::vector<float> points(static_cast<std::size_t>(n) * f);
  for (int j = 0; j < f; ++j) {
    for (int i = 0; i < n; ++i) {
      points[static_cast<std::size_t>(i) * f + j] =
          static_cast<float>(query(i, j));
    }
  }

  // Allocated before the threads start; workers only write raw storage.
  Rcpp::IntegerMatrix res(n, k);
  int *out = res.begin();
  const std::size_t rows = static_cast<std::size_t>(n);

  RcppThread::parallelFor(
      0, n,
      [&](int i) {
        std::vector<int32_t> items;
        index.get_nns_by_vector(&points[static_cast<std::size_t>(i) * f], k,
                                search_k, &items, NULL);
        const int found = std::min(static_cast<int>(items.size()), k);
        for (int j = 0; j < found; ++j) {
          out[static_cast<std::size_t>(j) * rows + i] = items[j] + 1;
        }
        for (int j = found; j < k; ++j) {
          out[static_cast<std::size_t>(j) * rows + i] = NA_INTEGER;
        }
      },
      nthreads);

  return res;
}
