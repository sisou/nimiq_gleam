import gleam/bytes_tree.{type BytesTree}
import gleam/result

import nimiq/serde

pub type RootData {
  RootData(
    // incomplete_from: Option(KeyNibbles),
    num_branches: Int,
    num_hybrids: Int,
    num_leaves: Int,
  )
}

pub fn serialize(buf: BytesTree, root_data: RootData) -> BytesTree {
  buf
  // incomplete_from None option
  |> serde.serialize_u8(0)
  |> serde.serialize_u64(root_data.num_branches)
  |> serde.serialize_u64(root_data.num_hybrids)
  |> serde.serialize_u64(root_data.num_leaves)
}

pub fn serialize_to_vec(root_data: RootData) -> BitArray {
  bytes_tree.new() |> serialize(root_data) |> bytes_tree.to_bit_array()
}

pub fn deserialize(buf: BitArray) -> Result(#(RootData, BitArray), String) {
  use #(_incomplete_from, rest) <- result.try(serde.deserialize_u8(buf))
  use #(num_branches, rest) <- result.try(serde.deserialize_u64(rest))
  use #(num_hybrids, rest) <- result.try(serde.deserialize_u64(rest))
  use #(num_leaves, rest) <- result.try(serde.deserialize_u64(rest))
  Ok(#(RootData(num_branches, num_hybrids, num_leaves), rest))
}

pub fn deserialize_all(buf: BitArray) -> Result(RootData, String) {
  case deserialize(buf) {
    Ok(#(root_data, <<>>)) -> Ok(root_data)
    Ok(_) -> Error("Invalid RootData: trailing bytes")
    Error(err) -> Error(err)
  }
}
