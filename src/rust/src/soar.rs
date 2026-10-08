//! SOAR: IVF where every point also lands in a second cell, picked by a rule
//! that accounts for its residual in the first. No Manhattan.

use ann_search_rs::prelude::SoarRule;
use ann_search_rs::utils::k_means_utils::{DEFAULT_ORTHOGONAL_LAMBDA, DEFAULT_SHIFT_MU};
use ann_search_rs::{build_soar_index, query_soar_index, query_soar_self};
use extendr_api::prelude::*;
use extendr_api::{Error, Result};

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};
use crate::utils::kmeans_params;

/// Resolve the spilling rule.
///
/// ### Params
///
/// * `rule` - `NULL`, `"nearest"`, `"shifted"` or `"orthogonal"`. Validated
///   on the R side.
/// * `param` - `mu` for shifted, `lambda` for orthogonal, ignored by nearest.
///   `NULL` takes the crate's value.
///
/// ### Returns
///
/// `None` to let the crate pick per metric, the rule otherwise.
fn soar_rule(rule: Nullable<String>, param: Nullable<f64>) -> Result<Option<SoarRule>> {
    let param = match param {
        Nullable::NotNull(p) => Some(p),
        Nullable::Null => None,
    };
    match rule {
        Nullable::Null => Ok(None),
        Nullable::NotNull(r) => match r.as_str() {
            "nearest" => Ok(Some(SoarRule::Nearest)),
            "shifted" => Ok(Some(SoarRule::Shifted {
                mu: param.unwrap_or(DEFAULT_SHIFT_MU),
            })),
            "orthogonal" => Ok(Some(SoarRule::Orthogonal {
                lambda: param.unwrap_or(DEFAULT_ORTHOGONAL_LAMBDA),
            })),
            other => Err(Error::Other(format!("unknown SOAR rule '{other}'"))),
        },
    }
}

/// Build a SOAR index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [SoarIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine")`.
/// @param nlist Integer or `NULL`. Number of Voronoi cells.
/// @param rule String or `NULL`. Spilling rule.
/// @param rule_param Numeric or `NULL`. `mu` (shifted) or `lambda`
/// (orthogonal).
/// @param kmeans_iters Integer or `NULL`. Lloyd iterations.
/// @param kmeans_balanced Boolean. Reseed starved centroids.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
/// @param verbose Boolean. Print progress.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_soar_build(
    data: RMatrix<f64>,
    metric: &str,
    nlist: Nullable<i32>,
    rule: Nullable<String>,
    rule_param: Nullable<f64>,
    kmeans_iters: Nullable<i32>,
    kmeans_balanced: bool,
    seed: i32,
    precision: &str,
    verbose: bool,
) -> Result<ExternalPtr<AnnIndex>> {
    let nlist = opt_usize(nlist);
    let rule = soar_rule(rule, rule_param)?;
    let km = kmeans_params(opt_usize(kmeans_iters), kmeans_balanced);
    let seed = seed as usize;
    build_prec!(data, precision, Soar, |mat| build_soar_index(
        mat,
        nlist,
        rule,
        km,
        metric,
        seed,
        verbose
    ))
}

/// Query a SOAR index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param nprobe Integer or `NULL`. Cells visited per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_soar_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    nprobe: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, nprobe) = (k as usize, opt_usize(nprobe));
    query_prec!(ptr, Soar, "soar", data, k, sqrt, |idx, q| {
        query_soar_index(q, idx, k, nprobe, return_dist, verbose)
    })
}

/// Self-query a SOAR index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param nprobe Integer or `NULL`. Cells visited per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_soar_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    nprobe: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, nprobe) = (k as usize, opt_usize(nprobe));
    self_prec!(ptr, Soar, "soar", k, sqrt, |idx| {
        query_soar_self(idx, k, nprobe, return_dist, verbose)
    })
}

extendr_module! {
    mod soar;
    fn rs_soar_build;
    fn rs_soar_query;
    fn rs_soar_self;
}
