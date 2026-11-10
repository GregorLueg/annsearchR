# annsearchR: Fast Approximate Nearest Neighbour Search

R interface to the Rust crate 'ann-search-rs'. Build an exact or
approximate nearest neighbour index once, keep it in memory behind an
'R6' object and query it as often as you like. Index types include
hierarchical navigable small world graphs (HNSW), 'Annoy' random
projection trees, inverted file indices (IVF), nearest neighbour descent
(NNDescent) and 'Vamana' graphs. Multi-threaded via the Rust crate
'Rayon', with 32-bit or 64-bit floating point storage. Methods are
described in Malkov and Yashunin (2020)
[doi:10.1109/TPAMI.2018.2889473](https://doi.org/10.1109/TPAMI.2018.2889473)
and Dong et al. (2011)
[doi:10.1145/1963405.1963487](https://doi.org/10.1145/1963405.1963487) .

## See also

Useful links:

- <https://gregorlueg.github.io/annsearchR/>

- <https://github.com/GregorLueg/annsearchR>

- Report bugs at <https://github.com/GregorLueg/annsearchR/issues>

## Author

**Maintainer**: Gregor Lueg <gregorlueg@me.com>

Authors:

- Gregor Lueg <gregorlueg@me.com>

Other contributors:

- Authors of the dependency Rust crates (see inst/AUTHORS file)
  \[contributor, copyright holder\]
