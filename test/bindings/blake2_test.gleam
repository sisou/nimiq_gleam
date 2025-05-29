import dummy
import gleam/bit_array
import gleeunit/should
import nimiq/bindings/blake2
import nimiq/utils/misc

pub fn blake2b_hash_test() {
  dummy.message
  |> bit_array.from_string()
  |> blake2.hash2b(32)
  |> misc.to_hex()
  |> should.equal(dummy.message_blake2b_hash_hex)
}
