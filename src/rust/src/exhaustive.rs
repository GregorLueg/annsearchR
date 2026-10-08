//! Brute-force index. Exact by construction, and the ground truth the
//! approximate indices are measured against.

use ann_search_rs::{build_exhaustive_index, query_exhaustive_index, query_exhaustive_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build an exhaustive index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [ExhaustiveIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param precision String. `"float"` or `"double"`.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
fn rs_exhaustive_build(
    data: RMatrix<f64>,
    metric: &str,
    precision: &str,
) -> Result<ExternalPtr<AnnIndex>> {
    build_prec!(data, precision, Exhaustive, |mat| Ok(
        build_exhaustive_index(mat, metric)
    ))
}

/// Query an exhaustive index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_exhaustive_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    query_prec!(ptr, Exhaustive, "exhaustive", data, k, sqrt, |idx, q| {
        query_exhaustive_index(q, idx, k, return_dist, verbose)
    })
}

/// Self-query an exhaustive index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_exhaustive_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    self_prec!(ptr, Exhaustive, "exhaustive", k, sqrt, |idx| {
        query_exhaustive_self(idx, k, return_dist, verbose)
    })
}

extendr_module! {
    mod exhaustive;
    fn rs_exhaustive_build;
    fn rs_exhaustive_query;
    fn rs_exhaustive_self;
}
