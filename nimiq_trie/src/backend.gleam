import gleam/dict.{type Dict}

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
