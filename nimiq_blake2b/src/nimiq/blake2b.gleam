import gblake2

pub const default = <<0:unit(8)-size(32)>>

/// Hashes the input using BLAKE2b with a 256-bit (32-byte) output.
pub fn hash(input: BitArray) -> BitArray {
  gblake2.hash2b(input, 32)
}
