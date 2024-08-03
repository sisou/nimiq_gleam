import gleam/bit_array
import gleam/result
import gleam/string
import gleeunit/should
import merkle/merkle_path.{MerklePath, MerklePathNode}

pub fn serialize_and_deserialize_merkle_path_test() {
  let nodes = [
    MerklePathNode(
      hash: bit_array.base16_decode(
        "7cc476224d3353f54da0a139576a6a9bc795b276973ac5cbef0785dcb8e48c25",
      )
        |> result.lazy_unwrap(fn() { panic as "base16 decode failed" }),
      is_left: True,
    ),
    MerklePathNode(
      hash: bit_array.base16_decode(
        "751111169689de46e939f1d90cbde5c046ae00448f0815105b38eb1837b1bb51",
      )
        |> result.lazy_unwrap(fn() { panic as "base16 decode failed" }),
      is_left: True,
    ),
  ]

  let path = MerklePath(nodes)

  let expected =
    "02c07cc476224d3353f54da0a139576a6a9bc795b276973ac5cbef0785dcb8e48c25751111169689de46e939f1d90cbde5c046ae00448f0815105b38eb1837b1bb51"

  path
  |> merkle_path.serialize()
  |> bit_array.base16_encode()
  |> string.lowercase()
  |> should.equal(expected)

  let path =
    merkle_path.deserialize_all(
      bit_array.base16_decode(expected)
      |> result.lazy_unwrap(fn() { panic as "base16 decode failed" }),
    )
    |> result.lazy_unwrap(fn() { panic as "deserialize failed" })

  path.nodes |> should.equal(nodes)
}
