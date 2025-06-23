import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None}
import gleam/order
import gleam/result
import gleam/string

import kvite.{type Kvite}
import valkyrie

import nimiq/trie/key_nibbles.{type KeyNibbles}

pub type Store {
  Memory(dict: Dict(String, BitArray))
  Redis(client: valkyrie.Connection, prefix: String)
  Sqlite(conn: Kvite, prefix: String)
}

pub type Backend {
  Backend(
    store: Store,
    get: fn(Backend, KeyNibbles) -> Result(BitArray, Nil),
    set: fn(Backend, KeyNibbles, BitArray) -> Nil,
    del: fn(Backend, KeyNibbles) -> Nil,
    keys: fn(Backend, KeyNibbles, KeyNibbles) -> List(KeyNibbles),
  )
}

// pub fn memory() -> Backend {
//   Backend(
//     store: Memory(dict: dict.new()),
//     get: fn(backend, key) {
//       let assert Memory(dict:) = backend.store
//       dict |> dict.get(key |> key_nibbles.to_string())
//     },
//     set: fn(backend, key, value) {
//       let assert Memory(dict:) = backend.store
//       let dict = dict |> dict.insert(key |> key_nibbles.to_string(), value)
//       Backend(..backend, store: Memory(dict:))
//     },
//     del: fn(backend, key) {
//       let assert Memory(dict:) = backend.store
//       let dict = dict |> dict.delete(key |> key_nibbles.to_string())
//       Backend(..backend, store: Memory(dict:))
//     },
//     keys: fn(backend, start_key, end_key) {
//       let start_key = start_key |> key_nibbles.to_string()
//       let end_key = end_key |> key_nibbles.to_string()

//       let key_length = start_key |> string.length()
//       let assert True = key_length == end_key |> string.length()

//       let assert Memory(dict:) = backend.store
//       dict
//       |> dict.keys()
//       |> list.filter(fn(key) {
//         key |> string.length() == key_length
//         && {
//           { key |> string.compare(start_key) == order.Gt }
//           || { key |> string.compare(start_key) == order.Eq }
//         }
//         && {
//           { key |> string.compare(end_key) == order.Lt }
//           || { key |> string.compare(end_key) == order.Eq }
//         }
//       })
//       |> list.sort(string.compare)
//       |> list.map(fn(str) {
//         let assert Ok(key) = key_nibbles.from_str(str)
//         key
//       })
//     },
//   )
// }

pub fn redis(
  redis_host host: String,
  redis_port port: Int,
  key_prefix prefix: String,
) -> Backend {
  let timeout = 1000

  let assert Ok(client) =
    valkyrie.default_config()
    |> valkyrie.host(host)
    |> valkyrie.port(port)
    // |> valkyrie.supervised_pool(size: 10, name: None, timeout: 1000)
    // |> valkyrie.create_connection(timeout)
    |> valkyrie.start_pool(3, None, timeout)

  Backend(
    store: Redis(client:, prefix:),
    get: fn(backend, key) {
      let assert Redis(client:, prefix:) = backend.store
      client
      |> valkyrie.get(prefix <> key |> key_nibbles.to_string(), timeout)
      |> result.replace_error(Nil)
      |> result.map(bit_array.base64_decode)
      |> result.flatten()
    },
    set: fn(backend, key, value) {
      let assert Redis(client:, prefix:) = backend.store
      let assert Ok(_) =
        client
        |> valkyrie.set(
          prefix <> key |> key_nibbles.to_string(),
          value |> bit_array.base64_encode(False),
          None,
          timeout,
        )
      Nil
    },
    del: fn(backend, key) {
      let assert Redis(client:, prefix:) = backend.store
      let assert Ok(_) =
        client
        |> valkyrie.del([prefix <> key |> key_nibbles.to_string()], timeout)
      Nil
    },
    keys: fn(backend, start_key, end_key) {
      let assert Redis(client:, prefix:) = backend.store
      let start_key = start_key |> key_nibbles.to_string()
      let end_key = end_key |> key_nibbles.to_string()

      let key_length = start_key |> string.length()
      let assert True = key_length == end_key |> string.length()

      let common_prefix =
        string_common_prefix(start_key, end_key) |> result.unwrap("*")

      let assert Ok(keys) =
        client |> valkyrie.keys(prefix <> common_prefix, timeout)

      let prefix_length = prefix |> string.length()

      keys
      |> list.map(fn(key) { key |> string.drop_start(prefix_length) })
      |> list.filter(fn(key) {
        key |> string.length() == key_length
        && {
          { key |> string.compare(start_key) == order.Gt }
          || { key |> string.compare(start_key) == order.Eq }
        }
        && {
          { key |> string.compare(end_key) == order.Lt }
          || { key |> string.compare(end_key) == order.Eq }
        }
      })
      |> list.sort(string.compare)
      |> list.map(fn(str) {
        let assert Ok(key) = key_nibbles.from_str(str)
        key
      })
    },
  )
}

pub fn sqlite(path: String, key_prefix prefix: String) -> Backend {
  let assert Ok(conn) =
    kvite.new()
    |> kvite.with_path(path)
    |> kvite.open()

  external_sqlite(conn, prefix)
}

pub fn external_sqlite(conn: Kvite, key_prefix prefix: String) -> Backend {
  Backend(
    store: Sqlite(conn:, prefix:),
    get: fn(backend, key) {
      let assert Sqlite(conn:, prefix:) = backend.store
      conn
      |> kvite.get(prefix <> key |> key_nibbles.to_string())
      |> result.replace_error(Nil)
      |> result.map(option.to_result(_, Nil))
      |> result.flatten()
    },
    set: fn(backend, key, value) {
      let assert Sqlite(conn:, prefix:) = backend.store
      let assert Ok(_) =
        conn |> kvite.set(prefix <> key |> key_nibbles.to_string(), value)
      Nil
    },
    del: fn(backend, key) {
      let assert Sqlite(conn:, prefix:) = backend.store
      let assert Ok(_) =
        conn |> kvite.del(prefix <> key |> key_nibbles.to_string())
      Nil
    },
    keys: fn(backend, start_key, end_key) {
      let assert Sqlite(conn:, prefix:) = backend.store
      let start_key = start_key |> key_nibbles.to_string()
      let end_key = end_key |> key_nibbles.to_string()

      let key_length = start_key |> string.length()
      let assert True = key_length == end_key |> string.length()

      let common_prefix =
        string_common_prefix(start_key, end_key) |> result.unwrap("")

      let assert Ok(keys) = conn |> kvite.keys_prefix(common_prefix)

      let prefix_length = prefix |> string.length()

      keys
      |> list.map(fn(key) { key |> string.drop_start(prefix_length) })
      |> list.filter(fn(key) {
        key |> string.length() == key_length
        && {
          { key |> string.compare(start_key) == order.Gt }
          || { key |> string.compare(start_key) == order.Eq }
        }
        && {
          { key |> string.compare(end_key) == order.Lt }
          || { key |> string.compare(end_key) == order.Eq }
        }
      })
      // Keys are already sorted by Kvite
      |> list.map(fn(str) {
        let assert Ok(key) = key_nibbles.from_str(str)
        key
      })
    },
  )
}

fn string_common_prefix(base: String, compare: String) -> Result(String, Nil) {
  do_string_common_prefix(base, compare, 1)
}

fn do_string_common_prefix(
  base: String,
  compare: String,
  length: Int,
) -> Result(String, Nil) {
  case base |> string.starts_with(compare |> string.slice(0, length)) {
    True -> do_string_common_prefix(base, compare, length + 1)
    False -> {
      let common_length = length - 1
      case common_length {
        0 -> Error(Nil)
        _ -> Ok(base |> string.slice(0, common_length))
      }
    }
  }
}
