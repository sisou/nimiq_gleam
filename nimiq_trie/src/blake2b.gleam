import bindings/blake2

pub fn hash(input: BitArray) -> BitArray {
  blake2.hash2b(input, 32)
}
