import gleam/bytes_tree
import gleeunit
import gleeunit/should
import nimiq/serde

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn serialize_deserialize_test() {
  // Serialize some data
  let buf =
    bytes_tree.new()
    |> serde.serialize_u8(42)
    |> serde.serialize_bool(True)
    |> serde.serialize_u32(65_535)
    |> serde.serialize_string("Hello, Gleam!")
    |> bytes_tree.to_bit_array()

  // Deserialize the same data
  let assert Ok(#(num_u8, buf)) = serde.deserialize_u8(buf)
  let assert Ok(#(bool_val, buf)) = serde.deserialize_bool(buf)
  let assert Ok(#(num_u32, buf)) = serde.deserialize_u32(buf)
  let assert Ok(#(str, rest)) = serde.deserialize_string(buf)

  // Ensure correctness
  should.equal(num_u8, 42)
  should.equal(bool_val, True)
  should.equal(num_u32, 65_535)
  should.equal(str, "Hello, Gleam!")
  should.equal(rest, <<>>)
}
