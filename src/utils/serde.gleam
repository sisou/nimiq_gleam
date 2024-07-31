import bindings/varint
import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}

pub fn serialize_bytes(buf: BytesBuilder, data: BitArray) -> BytesBuilder {
  buf
  // Encode the length of the data
  |> bytes_builder.append(varint.encode(bit_array.byte_size(data)))
  // Append the data
  |> bytes_builder.append(data)
}

pub fn deserialize_bytes(buf: BitArray) -> Result(#(BitArray, BitArray), String) {
  let #(len, rest) = varint.decode(buf)
  case rest {
    <<data:unit(8)-size(len)-bytes, rest:bits>> -> Ok(#(data, rest))
    _ -> Error("Invalid bytes: out of data")
  }
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
