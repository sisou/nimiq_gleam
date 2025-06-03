import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import nimiq/trie/key_nibbles.{type KeyNibbles}

import radish
import radish/client as radish_client

pub type Store {
  Memory(dict: Dict(String, BitArray))
  Redis(client: radish_client.Client, prefix: String)
}

pub type Backend {
  Backend(
    store: Store,
    get: fn(Backend, KeyNibbles) -> Result(BitArray, Nil),
    set: fn(Backend, KeyNibbles, BitArray) -> Backend,
    del: fn(Backend, KeyNibbles) -> Backend,
    keys: fn(Backend, KeyNibbles, KeyNibbles) -> List(KeyNibbles),
  )
}

pub fn memory() -> Backend {
  Backend(
    store: Memory(dict: dict.new()),
    get: fn(backend, key) {
      let assert Memory(dict:) = backend.store
      dict |> dict.get(key |> key_nibbles.to_string())
    },
    set: fn(backend, key, value) {
      let assert Memory(dict:) = backend.store
      let dict = dict |> dict.insert(key |> key_nibbles.to_string(), value)
      Backend(..backend, store: Memory(dict:))
    },
    del: fn(backend, key) {
      let assert Memory(dict:) = backend.store
      let dict = dict |> dict.delete(key |> key_nibbles.to_string())
      Backend(..backend, store: Memory(dict:))
    },
    keys: fn(backend, start_key, end_key) {
      let start_key = start_key |> key_nibbles.to_string()
      let end_key = end_key |> key_nibbles.to_string()

      let key_length = start_key |> string.length()
      let assert True = key_length == end_key |> string.length()

      let assert Memory(dict:) = backend.store
      dict
      |> dict.keys()
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

pub type RedisMeta {
  RedisMeta(
    encode: fn(BitArray) -> String,
    decode: fn(String) -> Result(BitArray, Nil),
  )
}

pub fn redis(
  redis_host host: String,
  redis_port port: Int,
  radish_options options: List(radish.StartOption),
  key_prefix prefix: String,
) -> Backend {
  // Extract the timeout option if it exists, defaulting to 1000 ms
  let timeout =
    options
    |> list.find_map(fn(option) {
      case option {
        radish.Timeout(timeout) -> Ok(timeout)
        _ -> Error(Nil)
      }
    })
    |> result.unwrap(1000)

  let assert Ok(client) = radish.start(host, port, options)

  Backend(
    store: Redis(client:, prefix:),
    get: fn(backend, key) {
      let assert Redis(client:, prefix:) = backend.store
      client
      |> radish.get(prefix <> key |> key_nibbles.to_string(), timeout)
      |> result.replace_error(Nil)
      |> result.map(bit_array.base64_decode)
      |> result.flatten()
    },
    set: fn(backend, key, value) {
      let assert Redis(client:, prefix:) = backend.store
      let assert Ok(_) =
        client
        |> radish.set(
          prefix <> key |> key_nibbles.to_string(),
          value |> bit_array.base64_encode(False),
          timeout,
        )
      backend
    },
    del: fn(backend, key) {
      let assert Redis(client:, prefix:) = backend.store
      let assert Ok(_) =
        client
        |> radish.del([prefix <> key |> key_nibbles.to_string()], timeout)
      backend
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
        client |> radish.keys(prefix <> common_prefix, timeout)

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
