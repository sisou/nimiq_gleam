import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/int
import gleam/result
import gleam/string
import gvarint

pub fn serialize_bytes(buf: BytesTree, data: BitArray) -> BytesTree {
  buf
  // Encode the length of the data
  |> bytes_tree.append(gvarint.encode(bit_array.byte_size(data)))
  // Append the data
  |> bytes_tree.append(data)
}

pub fn deserialize_bytes(buf: BitArray) -> Result(#(BitArray, BitArray), String) {
  let #(len, rest) = gvarint.decode(buf)
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

pub fn serialize_string(buf: BytesTree, str: String) -> BytesTree {
  buf
  // Encode the length of the string
  |> bytes_tree.append(gvarint.encode(string.byte_size(str)))
  // Append the string
  |> bytes_tree.append_string(str)
}

pub fn deserialize_string(buf: BitArray) -> Result(#(String, BitArray), String) {
  let #(len, rest) = gvarint.decode(buf)
  case rest {
    <<data:unit(8)-size(len)-bytes, rest:bits>> -> {
      case bit_array.to_string(data) {
        Ok(str) -> Ok(#(str, rest))
        Error(_) -> Error("Invalid string: invalid UTF-8")
      }
    }
    _ -> Error("Invalid string: out of data")
  }
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

fn serialize_int(buf: BytesTree, num: Int, bit_size: Int) -> BytesTree {
  buf
  |> bytes_tree.append(<<num:size(bit_size)>>)
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

fn deserialize_int(
  buf: BitArray,
  bit_size: Int,
) -> Result(#(Int, BitArray), String) {
  case buf {
    <<num:size(bit_size), rest:bits>> -> Ok(#(num, rest))
    _ -> Error("Invalid number: out of data")
  }
}

pub fn serialize_bool(buf: BytesTree, value: Bool) -> BytesTree {
  serialize_u8(buf, case value {
    True -> 1
    False -> 0
  })
}

pub fn deserialize_bool(buf: BitArray) -> Result(#(Bool, BitArray), String) {
  deserialize_u8(buf)
  |> result.map(fn(pair) {
    let #(num, rest) = pair
    case num {
      0 -> Ok(#(False, rest))
      1 -> Ok(#(True, rest))
      _ -> Error("Invalid bool: expected 0 or 1, got " <> int.to_string(num))
    }
  })
  |> result.flatten()
}
