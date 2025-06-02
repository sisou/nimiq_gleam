import gblake2
import gleam/bit_array
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn blake2b_hash_test() {
  assert "Nimiq rocks!"
    |> bit_array.from_string()
    |> gblake2.hash2b(32)
    |> bit_array.base16_encode()
    == "E493EE724B7D9D0AFE079DD7236DA36AB9DC5EF446AC16E52F232CF38A2CCB2F"
}
