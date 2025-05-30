import nimiq/bindings/blake2

pub const default = <<0:unit(8)-size(32)>>

pub fn hash(input: BitArray) -> BitArray {
  blake2.hash2b(input, 32)
}
