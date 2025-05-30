import gleeunit
import gleeunit/should
import gvarint

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn encode_decode_test() {
  // Encode a number into a bitarray
  gvarint.encode(120_000)
  |> should.equal(<<192, 169, 7>>)

  // Decode a number from a bitarray
  gvarint.decode(<<192, 169, 7>>)
  |> should.equal(#(120_000, <<>>))
}
