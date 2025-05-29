import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/string
import nimiq/bindings/varint
import nimiq/coin.{type Coin, Coin}

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

pub fn serialize_string(buf: BytesTree, str: String) -> BytesTree {
  buf
  // Encode the length of the string
  |> bytes_tree.append(varint.encode(string.byte_size(str)))
  // Append the string
  |> bytes_tree.append_string(str)
}

pub fn deserialize_string(buf: BitArray) -> Result(#(String, BitArray), String) {
  let #(len, rest) = varint.decode(buf)
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

pub fn serialize_int(buf: BytesTree, num: Int, bit_size: Int) -> BytesTree {
  buf
  |> bytes_tree.append(<<num:size(bit_size)>>)
}

pub fn deserialize_int(
  buf: BitArray,
  bit_size: Int,
) -> Result(#(Int, BitArray), String) {
  case buf {
    <<num:size(bit_size), rest:bits>> -> Ok(#(num, rest))
    _ -> Error("Invalid number: out of data")
  }
}

pub fn serialize_coin(buf: BytesTree, coin: Coin) -> BytesTree {
  serialize_int(buf, coin.luna, 64)
}

pub fn deserialize_coin(buf: BitArray) -> Result(#(Coin, BitArray), String) {
  case buf {
    <<luna:64, rest:bits>> -> Ok(#(Coin(luna), rest))
    _ -> Error("Invalid coin: out of data")
  }
}

pub fn serialize_bool(buf: BytesTree, value: Bool) -> BytesTree {
  serialize_int(
    buf,
    case value {
      True -> 1
      False -> 0
    },
    8,
  )
}

pub fn deserialize_bool(buf: BitArray) -> Result(#(Bool, BitArray), String) {
  case buf {
    <<0:8, rest:bits>> -> Ok(#(False, rest))
    <<1:8, rest:bits>> -> Ok(#(True, rest))
    _ -> Error("Invalid bool: out of data")
  }
}
