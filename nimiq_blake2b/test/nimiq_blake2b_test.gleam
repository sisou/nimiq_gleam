import gleam/bit_array
import gleeunit
import gleeunit/should

import nimiq/blake2b

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn blake2b_hash_test() {
  "Nimiq rocks!"
  |> bit_array.from_string()
  |> blake2b.hash()
  |> bit_array.base16_encode()
  |> should.equal(
    "E493EE724B7D9D0AFE079DD7236DA36AB9DC5EF446AC16E52F232CF38A2CCB2F",
  )
}
