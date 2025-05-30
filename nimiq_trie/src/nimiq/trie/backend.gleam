import base_x_gleam
import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/list
import gleam/order
import gleam/result
import gleam/string

import radish
import radish/client as radish_client

pub type Backend(store, meta) {
  Backend(
    store: store,
    meta: meta,
    get: fn(Backend(store, meta), BitArray) -> Result(BitArray, Nil),
    set: fn(Backend(store, meta), BitArray, BitArray) -> Backend(store, meta),
    delete: fn(Backend(store, meta), BitArray) -> Backend(store, meta),
    keys: fn(Backend(store, meta), BitArray, BitArray) -> List(BitArray),
  )
}

pub fn memory() -> Backend(Dict(BitArray, BitArray), Nil) {
  Backend(
    store: dict.new(),
    meta: Nil,
    get: fn(backend, key) { backend.store |> dict.get(key) },
    set: fn(backend, key, value) {
      Backend(..backend, store: backend.store |> dict.insert(key, value))
    },
    delete: fn(backend, key) {
      Backend(..backend, store: backend.store |> dict.delete(key))
    },
    keys: fn(backend, start_key, end_key) {
      backend.store
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
) -> Backend(radish_client.Client, RedisMeta) {
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

  let assert Ok(redis) = radish.start(host, port, options)

  // Use a costom base64 encoding that preserves bit order
  // https://github.com/dominictarr/d64
  let d64_alphabet =
    ".0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
  // Will return an error if the alphabet contains duplicates
  let assert Ok(#(encode, decode)) = base_x_gleam.generate(d64_alphabet)

  Backend(
    store: redis,
    meta: RedisMeta(encode:, decode:),
    get: fn(backend, key) {
      backend.store
      |> radish.get(key |> backend.meta.encode(), timeout)
      |> result.replace_error(Nil)
      |> result.map(backend.meta.decode)
      |> result.flatten()
    },
    set: fn(backend, key, value) {
      let assert Ok(_) =
        backend.store
        |> radish.set(
          key |> backend.meta.encode(),
          value |> backend.meta.encode(),
          timeout,
        )
      backend
    },
    delete: fn(backend, key) {
      let assert Ok(_) =
        backend.store
        |> radish.del([key |> backend.meta.encode()], timeout)
      backend
    },
    keys: fn(backend, start_key, end_key) {
      let start_key = start_key |> backend.meta.encode()
      let end_key = end_key |> backend.meta.encode()

      let common_prefix =
        string_common_prefix(start_key, end_key) |> result.unwrap("*")

      let assert Ok(keys) = backend.store |> radish.keys(common_prefix, timeout)

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
        let assert Ok(bytes) = backend.meta.decode(key)
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
