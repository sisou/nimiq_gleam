import gleam/dynamic/decode
import gleam/result

import sqlight

pub type SqliteKv {
  SqliteKv(conn: sqlight.Connection)
}

pub type SqliteError {
  NotFound
  Other(String)
}

pub fn open(path: String) -> Result(SqliteKv, String) {
  use conn <- result.try(
    sqlight.open(path)
    |> result.map_error(fn(err) { err.message }),
  )

  // Settings
  let assert Ok(_) = "PRAGMA main.synchronous = NORMAL;" |> sqlight.exec(conn)
  let assert Ok(_) = "PRAGMA main.journal_mode = WAL2;" |> sqlight.exec(conn)
  let assert Ok(_) =
    "PRAGMA main.auto_vacuum = INCREMENTAL;" |> sqlight.exec(conn)

  // Create table
  let assert Ok(_) =
    "CREATE TABLE IF NOT EXISTS kv (key TEXT PRIMARY KEY, value BLOB);"
    |> sqlight.exec(conn)

  Ok(SqliteKv(conn:))
}

pub fn get(kv: SqliteKv, key: String) -> Result(BitArray, SqliteError) {
  use rows <- result.try(
    "SELECT value FROM kv WHERE key = ?"
    |> sqlight.query(kv.conn, [sqlight.text(key)], {
      use value <- decode.field(0, decode.bit_array)
      decode.success(value)
    })
    |> result.map_error(fn(err) { Other(err.message) }),
  )

  case rows {
    [] -> Error(NotFound)
    [value] -> Ok(value)
    _ -> panic as "Unexpected number of rows returned"
  }
}

pub fn set(kv: SqliteKv, key: String, value: BitArray) -> Result(Nil, String) {
  use _res <- result.try(
    "INSERT OR REPLACE INTO kv (key, value) VALUES (?, ?);"
    |> sqlight.query(
      kv.conn,
      [sqlight.text(key), sqlight.blob(value)],
      decode.int,
    )
    |> result.map_error(fn(err) { err.message }),
  )
  Ok(Nil)
}

pub fn del(kv: SqliteKv, key: String) -> Result(Nil, String) {
  use _res <- result.try(
    "DELETE FROM kv WHERE key = ?;"
    |> sqlight.query(kv.conn, [sqlight.text(key)], decode.int)
    |> result.map_error(fn(err) { err.message }),
  )
  Ok(Nil)
}

pub fn keys(kv: SqliteKv) -> Result(List(String), String) {
  "SELECT key FROM kv;"
  |> sqlight.query(kv.conn, [], {
    use key <- decode.field(0, decode.string)
    decode.success(key)
  })
  |> result.map_error(fn(err) { err.message })
}

pub fn begin_transaction(kv: SqliteKv) -> Result(Nil, String) {
  use _res <- result.try(
    "BEGIN TRANSACTION;"
    |> sqlight.exec(kv.conn)
    |> result.map_error(fn(err) { err.message }),
  )
  Ok(Nil)
}

pub fn commit_transaction(kv: SqliteKv) -> Result(Nil, String) {
  use _res <- result.try(
    "COMMIT;"
    |> sqlight.exec(kv.conn)
    |> result.map_error(fn(err) { err.message }),
  )
  Ok(Nil)
}
