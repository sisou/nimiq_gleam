import gleam/bit_array
import gleeunit/should
import merkle/merkle_path.{MerklePath, MerklePathNode}

pub fn serialize_and_deserialize_merkle_path_test() {
  let assert Ok(hash1) =
    "7cc476224d3353f54da0a139576a6a9bc795b276973ac5cbef0785dcb8e48c25"
    |> bit_array.base16_decode()
  let assert Ok(hash2) =
    "751111169689de46e939f1d90cbde5c046ae00448f0815105b38eb1837b1bb51"
    |> bit_array.base16_decode()

  let nodes = [
    MerklePathNode(hash: hash1, is_left: True),
    MerklePathNode(hash: hash2, is_left: True),
  ]

  let path = MerklePath(nodes)

  let assert Ok(expected) =
    "02c07cc476224d3353f54da0a139576a6a9bc795b276973ac5cbef0785dcb8e48c25751111169689de46e939f1d90cbde5c046ae00448f0815105b38eb1837b1bb51"
    |> bit_array.base16_decode()

  path
  |> merkle_path.serialize()
  |> should.equal(expected)

  let assert Ok(path) = merkle_path.deserialize_all(expected)

  path.nodes |> should.equal(nodes)
}
