import bindings/blake2
import dummy
import gleam/bit_array
import gleam/string
import gleeunit/should

pub fn blake2b_hash_test() {
  dummy.message
  |> bit_array.from_string()
  |> blake2.hash2b(32)
  |> bit_array.base16_encode()
  |> string.lowercase()
  |> should.equal(dummy.message_blake2b_hash_hex)
}
