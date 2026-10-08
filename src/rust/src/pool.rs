//! Thread control.
//!
//! Not `rayon::ThreadPoolBuilder::build_global()`: that succeeds once per
//! process and errors on every later call. A stored pool plus
//! `ThreadPool::install` can be rebuilt as often as the user likes, and the
//! crate's internal parallel iterators pick the installed pool up.

use std::sync::{Arc, RwLock};

use extendr_api::prelude::*;
use extendr_api::{Error, Result};

//////////////////
// Shared state //
//////////////////

/// The pool `rs_set_threads` installed, or `None` for rayon's global one.
static POOL: RwLock<Option<Arc<rayon::ThreadPool>>> = RwLock::new(None);

/// Message for a poisoned lock. Cannot happen: the only work under the write
/// guard is one assignment.
const POISONED: &str = "thread pool lock poisoned";

/////////////////
// Entry point //
/////////////////

/// Run `f` on the configured pool, or on rayon's global pool if none is set.
///
/// `f` must not touch the R API: it runs on rayon workers.
///
/// ### Params
///
/// * `f` - The build or query.
///
/// ### Returns
///
/// Whatever `f` returns.
pub fn run<R: Send>(f: impl FnOnce() -> R + Send) -> R {
    let pool = POOL.read().expect(POISONED).clone();
    match pool {
        Some(p) => p.install(f),
        None => f(),
    }
}

///////
// R //
///////

/// Set the number of threads used for builds and queries
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Installs a dedicated Rayon pool. Use [ann_set_threads()] instead.
///
/// @param n Integer. Thread count. `0L` returns to Rayon's global pool, which
/// honours `RAYON_NUM_THREADS`.
///
/// @returns Invisible `NULL`.
///
/// @keywords internal
#[extendr]
fn rs_set_threads(n: i32) -> Result<()> {
    let new = if n <= 0 {
        None
    } else {
        let pool = rayon::ThreadPoolBuilder::new()
            .num_threads(n as usize)
            .build()
            .map_err(|e| Error::Other(format!("could not build thread pool: {e}")))?;
        Some(Arc::new(pool))
    };
    *POOL.write().expect(POISONED) = new;
    Ok(())
}

/// Number of threads used for builds and queries
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [ann_get_threads()] instead.
///
/// @returns Integer. The configured pool's size, or Rayon's global pool size.
///
/// @keywords internal
#[extendr]
fn rs_get_threads() -> i32 {
    let pool = POOL.read().expect(POISONED).clone();
    match pool {
        Some(p) => p.current_num_threads() as i32,
        None => rayon::current_num_threads() as i32,
    }
}

extendr_module! {
    mod pool;
    fn rs_set_threads;
    fn rs_get_threads;
}
