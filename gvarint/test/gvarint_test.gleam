import gleeunit
import gvarint

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn encode_decode_test() {
  // Encode a number into a bitarray
  assert gvarint.encode(120_000) == <<192, 169, 7>>

  // Decode a number from a bitarray
  assert gvarint.decode(<<192, 169, 7>>) == #(120_000, <<>>)
}
