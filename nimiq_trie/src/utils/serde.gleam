import gleam/bytes_tree.{type BytesTree}

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
