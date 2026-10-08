# Package index

## Exact indices

Recall 1 by construction

- [`ExhaustiveIndex`](https://gregorlueg.github.io/annsearchR/reference/ExhaustiveIndex.md)
  : Exhaustive (brute-force) index
- [`KmknnIndex`](https://gregorlueg.github.io/annsearchR/reference/KmknnIndex.md)
  : kMkNN index

## Tree indices

Random projection and space partitioning forests

- [`AnnoyIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnoyIndex.md)
  : Annoy index
- [`KdTreeIndex`](https://gregorlueg.github.io/annsearchR/reference/KdTreeIndex.md)
  : kd forest index
- [`BallTreeIndex`](https://gregorlueg.github.io/annsearchR/reference/BallTreeIndex.md)
  : Ball tree index

## Partition indices

k-means cells and hashing

- [`IvfIndex`](https://gregorlueg.github.io/annsearchR/reference/IvfIndex.md)
  : IVF index
- [`SoarIndex`](https://gregorlueg.github.io/annsearchR/reference/SoarIndex.md)
  : SOAR index
- [`LshIndex`](https://gregorlueg.github.io/annsearchR/reference/LshIndex.md)
  : LSH index

## Graph indices

Navigable neighbour graphs

- [`HnswIndex`](https://gregorlueg.github.io/annsearchR/reference/HnswIndex.md)
  : HNSW index
- [`NNDescentIndex`](https://gregorlueg.github.io/annsearchR/reference/NNDescentIndex.md)
  : NN-Descent index
- [`VamanaIndex`](https://gregorlueg.github.io/annsearchR/reference/VamanaIndex.md)
  : Vamana index
- [`NsgIndex`](https://gregorlueg.github.io/annsearchR/reference/NsgIndex.md)
  : NSG index
- [`RnnDescentIndex`](https://gregorlueg.github.io/annsearchR/reference/RnnDescentIndex.md)
  : Relative NN-Descent index

## Shared interface

Querying, saving and loading any index

- [`AnnIndex`](https://gregorlueg.github.io/annsearchR/reference/AnnIndex.md)
  : Base class for all nearest neighbour indices

- [`predict(`*`<AnnIndex>`*`)`](https://gregorlueg.github.io/annsearchR/reference/predict.AnnIndex.md)
  : Query an index

- [`load_ann_index()`](https://gregorlueg.github.io/annsearchR/reference/load_ann_index.md)
  :

  Load an index written by `$save()`

## Utilities

- [`ann_set_threads()`](https://gregorlueg.github.io/annsearchR/reference/ann_set_threads.md)
  : Set the number of threads for index builds and queries
- [`ann_get_threads()`](https://gregorlueg.github.io/annsearchR/reference/ann_get_threads.md)
  : Number of threads used for index builds and queries
- [`knn_recall()`](https://gregorlueg.github.io/annsearchR/reference/knn_recall.md)
  : Recall of an approximate kNN result

## Synthetic data

The generators behind the ann-search-rs benchmark tables

- [`generate_clustered_data()`](https://gregorlueg.github.io/annsearchR/reference/generate_clustered_data.md)
  : Generate clustered synthetic data
- [`generate_correlated_data()`](https://gregorlueg.github.io/annsearchR/reference/generate_correlated_data.md)
  : Generate correlated synthetic data
- [`generate_low_rank_data()`](https://gregorlueg.github.io/annsearchR/reference/generate_low_rank_data.md)
  : Generate low-rank synthetic data
- [`generate_cell_embeddings()`](https://gregorlueg.github.io/annsearchR/reference/generate_cell_embeddings.md)
  : Generate synthetic cell embeddings
- [`subsample_queries()`](https://gregorlueg.github.io/annsearchR/reference/subsample_queries.md)
  : Subsample queries from a dataset

## Rust wrappers

Everything rusty - only use this if you know what you are doing…

- [`rs_ann_info()`](https://gregorlueg.github.io/annsearchR/reference/rs_ann_info.md)
  **\[experimental\]** : Describe an index
- [`rs_ann_load()`](https://gregorlueg.github.io/annsearchR/reference/rs_ann_load.md)
  **\[experimental\]** : Load an index from a directory
- [`rs_ann_save()`](https://gregorlueg.github.io/annsearchR/reference/rs_ann_save.md)
  **\[experimental\]** : Save an index to a directory
- [`rs_annoy_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_annoy_build.md)
  **\[experimental\]** : Build an Annoy index
- [`rs_annoy_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_annoy_query.md)
  **\[experimental\]** : Query an Annoy index
- [`rs_annoy_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_annoy_self.md)
  **\[experimental\]** : Self-query an Annoy index
- [`rs_balltree_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_balltree_build.md)
  **\[experimental\]** : Build a ball tree index
- [`rs_balltree_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_balltree_query.md)
  **\[experimental\]** : Query a ball tree index
- [`rs_balltree_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_balltree_self.md)
  **\[experimental\]** : Self-query a ball tree index
- [`rs_data_cell_embeddings()`](https://gregorlueg.github.io/annsearchR/reference/rs_data_cell_embeddings.md)
  **\[experimental\]** : Generate synthetic cell embeddings
- [`rs_data_clustered()`](https://gregorlueg.github.io/annsearchR/reference/rs_data_clustered.md)
  **\[experimental\]** : Generate clustered synthetic data
- [`rs_data_correlated()`](https://gregorlueg.github.io/annsearchR/reference/rs_data_correlated.md)
  **\[experimental\]** : Generate correlated synthetic data
- [`rs_data_low_rank()`](https://gregorlueg.github.io/annsearchR/reference/rs_data_low_rank.md)
  **\[experimental\]** : Generate low-rank synthetic data
- [`rs_exhaustive_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_exhaustive_build.md)
  **\[experimental\]** : Build an exhaustive index
- [`rs_exhaustive_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_exhaustive_query.md)
  **\[experimental\]** : Query an exhaustive index
- [`rs_exhaustive_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_exhaustive_self.md)
  **\[experimental\]** : Self-query an exhaustive index
- [`rs_get_threads()`](https://gregorlueg.github.io/annsearchR/reference/rs_get_threads.md)
  **\[experimental\]** : Number of threads used for builds and queries
- [`rs_hnsw_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_hnsw_build.md)
  **\[experimental\]** : Build an HNSW index
- [`rs_hnsw_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_hnsw_query.md)
  **\[experimental\]** : Query an HNSW index
- [`rs_hnsw_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_hnsw_self.md)
  **\[experimental\]** : Self-query an HNSW index
- [`rs_ivf_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_ivf_build.md)
  **\[experimental\]** : Build an IVF index
- [`rs_ivf_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_ivf_query.md)
  **\[experimental\]** : Query an IVF index
- [`rs_ivf_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_ivf_self.md)
  **\[experimental\]** : Self-query an IVF index
- [`rs_kdtree_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_kdtree_build.md)
  **\[experimental\]** : Build a kd forest index
- [`rs_kdtree_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_kdtree_query.md)
  **\[experimental\]** : Query a kd forest index
- [`rs_kdtree_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_kdtree_self.md)
  **\[experimental\]** : Self-query a kd forest index
- [`rs_kmknn_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_kmknn_build.md)
  **\[experimental\]** : Build a kMkNN index
- [`rs_kmknn_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_kmknn_query.md)
  **\[experimental\]** : Query a kMkNN index
- [`rs_kmknn_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_kmknn_self.md)
  **\[experimental\]** : Self-query a kMkNN index
- [`rs_knn_recall()`](https://gregorlueg.github.io/annsearchR/reference/rs_knn_recall.md)
  **\[experimental\]** : Recall of an approximate kNN result against
  ground truth
- [`rs_lsh_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_lsh_build.md)
  **\[experimental\]** : Build an LSH index
- [`rs_lsh_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_lsh_query.md)
  **\[experimental\]** : Query an LSH index
- [`rs_lsh_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_lsh_self.md)
  **\[experimental\]** : Self-query an LSH index
- [`rs_nndescent_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_nndescent_build.md)
  **\[experimental\]** : Build an NN-Descent index
- [`rs_nndescent_extract()`](https://gregorlueg.github.io/annsearchR/reference/rs_nndescent_extract.md)
  **\[experimental\]** : Extract the converged NN-Descent graph
- [`rs_nndescent_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_nndescent_query.md)
  **\[experimental\]** : Query an NN-Descent index
- [`rs_nndescent_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_nndescent_self.md)
  **\[experimental\]** : Self-query an NN-Descent index
- [`rs_nsg_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_nsg_build.md)
  **\[experimental\]** : Build an NSG index
- [`rs_nsg_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_nsg_query.md)
  **\[experimental\]** : Query an NSG index
- [`rs_nsg_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_nsg_self.md)
  **\[experimental\]** : Self-query an NSG index
- [`rs_rnndescent_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_rnndescent_build.md)
  **\[experimental\]** : Build a relative NN-Descent index
- [`rs_rnndescent_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_rnndescent_query.md)
  **\[experimental\]** : Query a relative NN-Descent index
- [`rs_rnndescent_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_rnndescent_self.md)
  **\[experimental\]** : Self-query a relative NN-Descent index
- [`rs_set_threads()`](https://gregorlueg.github.io/annsearchR/reference/rs_set_threads.md)
  **\[experimental\]** : Set the number of threads used for builds and
  queries
- [`rs_soar_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_soar_build.md)
  **\[experimental\]** : Build a SOAR index
- [`rs_soar_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_soar_query.md)
  **\[experimental\]** : Query a SOAR index
- [`rs_soar_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_soar_self.md)
  **\[experimental\]** : Self-query a SOAR index
- [`rs_subsample_queries()`](https://gregorlueg.github.io/annsearchR/reference/rs_subsample_queries.md)
  **\[experimental\]** : Subsample queries with noise
- [`rs_vamana_build()`](https://gregorlueg.github.io/annsearchR/reference/rs_vamana_build.md)
  **\[experimental\]** : Build a Vamana index
- [`rs_vamana_query()`](https://gregorlueg.github.io/annsearchR/reference/rs_vamana_query.md)
  **\[experimental\]** : Query a Vamana index
- [`rs_vamana_self()`](https://gregorlueg.github.io/annsearchR/reference/rs_vamana_self.md)
  **\[experimental\]** : Self-query a Vamana index
