import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/list
import gleam/order
import gleam/result
import gleam/string

import base_x_gleam
import radish
import radish/client as radish_client

pub type Store {
  Memory(dict: Dict(BitArray, BitArray))
  Redis(
    client: radish_client.Client,
    encode: fn(BitArray) -> String,
    decode: fn(String) -> Result(BitArray, Nil),
  )
}

pub type Backend {
  Backend(
    store: Store,
    get: fn(Backend, BitArray) -> Result(BitArray, Nil),
    set: fn(Backend, BitArray, BitArray) -> Backend,
    delete: fn(Backend, BitArray) -> Backend,
    keys: fn(Backend, BitArray, BitArray) -> List(BitArray),
  )
}

pub fn memory() -> Backend {
  Backend(
    store: Memory(dict: dict.new()),
    get: fn(backend, key) {
      let assert Memory(dict:) = backend.store
      dict |> dict.get(key)
    },
    set: fn(backend, key, value) {
      let assert Memory(dict:) = backend.store
      let dict = dict |> dict.insert(key, value)
      Backend(..backend, store: Memory(dict:))
    },
    delete: fn(backend, key) {
      let assert Memory(dict:) = backend.store
      let dict = dict |> dict.delete(key)
      Backend(..backend, store: Memory(dict:))
    },
    keys: fn(backend, start_key, end_key) {
      let assert Memory(dict:) = backend.store
      dict
      |> dict.keys()
      |> list.filter(fn(key) {
        {
          { key |> bit_array.compare(start_key) == order.Gt }
          || { key |> bit_array.compare(start_key) == order.Eq }
        }
        && {
          { key |> bit_array.compare(end_key) == order.Lt }
          || { key |> bit_array.compare(end_key) == order.Eq }
        }
      })
      |> list.sort(bit_array.compare)
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
  host: String,
  port: Int,
  options: List(radish.StartOption),
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

  // Use a costom base64 encoding that preserves bit order
  // https://github.com/dominictarr/d64
  let d64_alphabet =
    ".0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
  // Will return an error if the alphabet contains duplicates
  let assert Ok(#(encode, decode)) = base_x_gleam.generate(d64_alphabet)

  Backend(
    store: Redis(client:, encode:, decode:),
    get: fn(backend, key) {
      let assert Redis(client:, encode:, decode:) = backend.store
      client
      |> radish.get(key |> encode(), timeout)
      |> result.replace_error(Nil)
      |> result.map(decode)
      |> result.flatten()
    },
    set: fn(backend, key, value) {
      let assert Redis(client:, encode:, ..) = backend.store
      let assert Ok(_) =
        client
        |> radish.set(key |> encode(), value |> encode(), timeout)
      backend
    },
    delete: fn(backend, key) {
      let assert Redis(client:, encode:, ..) = backend.store
      let assert Ok(_) =
        client
        |> radish.del([key |> encode()], timeout)
      backend
    },
    keys: fn(backend, start_key, end_key) {
      let assert Redis(client:, encode:, decode:) = backend.store
      let start_key = start_key |> encode()
      let end_key = end_key |> encode()

      let common_prefix =
        string_common_prefix(start_key, end_key) |> result.unwrap("*")

      let assert Ok(keys) = client |> radish.keys(common_prefix, timeout)

      keys
      |> list.filter(fn(key) {
        {
          { key |> string.compare(start_key) == order.Gt }
          || { key |> string.compare(start_key) == order.Eq }
        }
        && {
          { key |> string.compare(end_key) == order.Lt }
          || { key |> string.compare(end_key) == order.Eq }
        }
      })
      |> list.sort(string.compare)
      |> list.map(fn(key) {
        let assert Ok(bytes) = decode(key)
        bytes
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
