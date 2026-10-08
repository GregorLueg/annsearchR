//! Multi-probe LSH over random projections. Cheapest build here, weakest
//! recall per unit of query time. No Manhattan.

use ann_search_rs::{build_lsh_index, query_lsh_index, query_lsh_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build an LSH index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [LshIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine")`.
/// @param num_tables Integer. Independent hash tables.
/// @param bits_per_hash Integer. Bits per bucket code.
/// @param slot_bits Integer or `NULL`. Bits per quantised projection.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
fn rs_lsh_build(
    data: RMatrix<f64>,
    metric: &str,
    num_tables: i32,
    bits_per_hash: i32,
    slot_bits: Nullable<i32>,
    seed: i32,
    precision: &str,
) -> Result<ExternalPtr<AnnIndex>> {
    let (num_tables, bits_per_hash) = (num_tables as usize, bits_per_hash as usize);
    let (slot_bits, seed) = (opt_usize(slot_bits), seed as usize);
    build_prec!(data, precision, Lsh, |mat| build_lsh_index(
        mat,
        metric,
        num_tables,
        bits_per_hash,
        slot_bits,
        seed
    ))
}

/// Query an LSH index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param n_probe Integer or `NULL`. Buckets probed per table. `NULL` means
/// one per projection.
/// @param max_candidates Integer or `NULL`. Cap on candidates scored.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_lsh_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    n_probe: Nullable<i32>,
    max_candidates: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    let (n_probe, max_candidates) = (opt_usize(n_probe), opt_usize(max_candidates));
    query_prec!(ptr, Lsh, "lsh", data, k, sqrt, |idx, q| {
        let probes = n_probe.unwrap_or_else(|| idx.num_projections());
        query_lsh_index(q, idx, k, probes, max_candidates, return_dist, verbose)
    })
}

/// Self-query an LSH index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param n_probe Integer or `NULL`. Buckets probed per table.
/// @param max_candidates Integer or `NULL`. Cap on candidates scored.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_lsh_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    n_probe: Nullable<i32>,
    max_candidates: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    let (n_probe, max_candidates) = (opt_usize(n_probe), opt_usize(max_candidates));
    self_prec!(ptr, Lsh, "lsh", k, sqrt, |idx| {
        query_lsh_self(idx, k, n_probe, max_candidates, return_dist, verbose)
    })
}

extendr_module! {
    mod lsh;
    fn rs_lsh_build;
    fn rs_lsh_query;
    fn rs_lsh_self;
}
