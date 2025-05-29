import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/list
import gleam/result

import radish
import radish/client as radish_client

pub type Backend(store) {
  Backend(
    store: store,
    get: fn(Backend(store), BitArray) -> Result(BitArray, Nil),
    set: fn(Backend(store), BitArray, BitArray) -> Backend(store),
    delete: fn(Backend(store), BitArray) -> Backend(store),
    keys: fn(Backend(store)) -> List(BitArray),
  )
}

pub fn memory() -> Backend(Dict(BitArray, BitArray)) {
  Backend(
    store: dict.new(),
    get: fn(backend, key) { backend.store |> dict.get(key) },
    set: fn(backend, key, value) {
      Backend(..backend, store: backend.store |> dict.insert(key, value))
    },
    delete: fn(backend, key) {
      Backend(..backend, store: backend.store |> dict.delete(key))
    },
    keys: fn(backend) { backend.store |> dict.keys() },
  )
}

pub fn redis(
  host: String,
  port: Int,
  options: List(radish.StartOption),
) -> Backend(radish_client.Client) {
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

  Backend(
    store: redis,
    get: fn(backend, key) {
      backend.store
      |> radish.get(key |> bit_array.base64_encode(False), timeout)
      |> result.replace_error(Nil)
      |> result.map(bit_array.base64_decode)
      |> result.flatten()
    },
    set: fn(backend, key, value) {
      let assert Ok(_) =
        backend.store
        |> radish.set(
          key |> bit_array.base64_encode(False),
          value |> bit_array.base64_encode(False),
          timeout,
        )
      backend
    },
    delete: fn(backend, key) {
      let assert Ok(_) =
        backend.store
        |> radish.del([key |> bit_array.base64_encode(False)], timeout)
      backend
    },
    keys: fn(backend) {
      let assert Ok(keys) = backend.store |> radish.keys("*", timeout)
      keys
      |> list.map(fn(key) {
        let assert Ok(decoded) = bit_array.base64_decode(key)
        decoded
      })
    },
  )
}
