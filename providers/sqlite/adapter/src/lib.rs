//! SQLite provider adapter: WIT `store` world onto rusqlite.
//!
//! Unlike the pure providers (`sha256`, `text-width`), this component is
//! `std` and imports `wasi:filesystem` — database files persist under
//! directories the manifest grants. Connections are `u32` handles into a
//! process-wide table because resource handles cannot cross the provider
//! boundary; every other value is plain WIT data.

mod bindings {
    wit_bindgen::generate!({
        world: "sqlite-provider",
        path: "../wit",
    });
}

use bindings::exports::ai_direct::sqlite::store::{
    Guest, ResultSet, Row, Value,
};
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

struct State {
    next: u32,
    connections: HashMap<u32, rusqlite::Connection>,
}

fn state() -> &'static Mutex<State> {
    static STATE: OnceLock<Mutex<State>> = OnceLock::new();
    STATE.get_or_init(|| {
        Mutex::new(State {
            next: 1,
            connections: HashMap::new(),
        })
    })
}

fn to_sql(value: &Value) -> rusqlite::types::Value {
    match value {
        Value::IntVal(v) => rusqlite::types::Value::Integer(*v),
        Value::RealVal(v) => rusqlite::types::Value::Real(*v),
        Value::TextVal(v) => {
            rusqlite::types::Value::Text(v.clone())
        }
        Value::BlobVal(v) => rusqlite::types::Value::Blob(v.clone()),
        Value::NullVal => rusqlite::types::Value::Null,
    }
}

fn from_sql(value: rusqlite::types::Value) -> Value {
    match value {
        rusqlite::types::Value::Null => Value::NullVal,
        rusqlite::types::Value::Integer(v) => Value::IntVal(v),
        rusqlite::types::Value::Real(v) => Value::RealVal(v),
        rusqlite::types::Value::Text(v) => Value::TextVal(v),
        rusqlite::types::Value::Blob(v) => Value::BlobVal(v),
    }
}

struct Component;

impl Guest for Component {
    fn open(path: String) -> Result<u32, String> {
        let connection =
            rusqlite::Connection::open(&path).map_err(|e| e.to_string())?;
        let mut state = state().lock().map_err(|e| e.to_string())?;
        let handle = state.next;
        state.next = state.next.wrapping_add(1).max(1);
        state.connections.insert(handle, connection);
        Ok(handle)
    }

    fn exec(handle: u32, sql: String, params: Vec<Value>) -> Result<ResultSet, String> {
        let params: Vec<rusqlite::types::Value> =
            params.iter().map(to_sql).collect();
        let state = state().lock().map_err(|e| e.to_string())?;
        let connection = state
            .connections
            .get(&handle)
            .ok_or_else(|| format!("unknown handle {handle}"))?;
        let mut statement =
            connection.prepare(&sql).map_err(|e| e.to_string())?;
        let columns: Vec<String> =
            statement.column_names().iter().map(|s| s.to_string()).collect();
        let width = columns.len();
        let mut query = statement
            .query(rusqlite::params_from_iter(params.iter()))
            .map_err(|e| e.to_string())?;
        let mut rows = Vec::new();
        while let Some(row) = query.next().map_err(|e| e.to_string())? {
            let mut values = Vec::with_capacity(width);
            for i in 0..width {
                let value: rusqlite::types::Value =
                    row.get(i).map_err(|e| e.to_string())?;
                values.push(from_sql(value));
            }
            rows.push(Row { values });
        }
        Ok(ResultSet { columns, rows })
    }

    fn close(handle: u32) -> Result<(), String> {
        let mut state = state().lock().map_err(|e| e.to_string())?;
        state.connections.remove(&handle).map(|_| ()).ok_or_else(|| {
            format!("unknown handle {handle}")
        })
    }
}

bindings::export!(Component with_types_in bindings);
