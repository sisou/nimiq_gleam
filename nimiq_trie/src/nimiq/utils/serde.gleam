import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}

import nimiq/bindings/varint

pub fn serialize_bytes(buf: BytesTree, data: BitArray) -> BytesTree {
  buf
  // Encode the length of the data
  |> bytes_tree.append(varint.encode(bit_array.byte_size(data)))
  // Append the data
  |> bytes_tree.append(data)
}

pub fn deserialize_bytes(buf: BitArray) -> Result(#(BitArray, BitArray), String) {
  let #(len, rest) = varint.decode(buf)
  case rest {
    <<data:unit(8)-size(len)-bytes, rest:bits>> -> Ok(#(data, rest))
    _ -> Error("Invalid bytes: out of data")
  }
}

pub fn serialize_bitarray(buf: BytesTree, data: BitArray) -> BytesTree {
  buf |> bytes_tree.append(data)
}

pub fn deserialize_bitarray(
  buf: BitArray,
  length: Int,
) -> Result(#(BitArray, BitArray), String) {
  case buf {
    <<data:unit(8)-size(length)-bytes, rest:bits>> -> Ok(#(data, rest))
    _ -> Error("Invalid bitarray: out of data")
  }
}

fn serialize_int(buf: BytesTree, num: Int, bit_size: Int) -> BytesTree {
  buf
  |> bytes_tree.append(<<num:size(bit_size)>>)
}

pub fn serialize_u8(buf: BytesTree, num: Int) -> BytesTree {
  buf |> serialize_int(num, 8)
}

pub fn serialize_u16(buf: BytesTree, num: Int) -> BytesTree {
  buf |> serialize_int(num, 16)
}

pub fn serialize_u32(buf: BytesTree, num: Int) -> BytesTree {
  buf |> serialize_int(num, 32)
}

pub fn serialize_u64(buf: BytesTree, num: Int) -> BytesTree {
  buf |> serialize_int(num, 64)
}

fn deserialize_int(
  buf: BitArray,
  bit_size: Int,
) -> Result(#(Int, BitArray), String) {
  case buf {
    <<num:size(bit_size), rest:bits>> -> Ok(#(num, rest))
    _ -> Error("Invalid number: out of data")
  }
}

pub fn deserialize_u8(buf: BitArray) -> Result(#(Int, BitArray), String) {
  buf |> deserialize_int(8)
}

pub fn deserialize_u16(buf: BitArray) -> Result(#(Int, BitArray), String) {
  buf |> deserialize_int(16)
}

pub fn deserialize_u32(buf: BitArray) -> Result(#(Int, BitArray), String) {
  buf |> deserialize_int(32)
}

pub fn deserialize_u64(buf: BitArray) -> Result(#(Int, BitArray), String) {
  buf |> deserialize_int(64)
}
