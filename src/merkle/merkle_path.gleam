import gleam/bit_array
import gleam/bytes_builder
import gleam/list

pub type MerklePath {
  MerklePath(nodes: List(MerklePathNode))
}

pub fn empty() -> MerklePath {
  MerklePath(nodes: [])
}

pub fn serialize(path: MerklePath) -> BitArray {
  bytes_builder.new()
  |> bytes_builder.append(<<list.length(path.nodes):8>>)
  |> bytes_builder.append(compress(path.nodes))
  |> bytes_builder.append(
    path.nodes |> list.map(fn(node) { node.hash }) |> bit_array.concat(),
  )
  |> bytes_builder.to_bit_array()
}

fn compress(nodes: List(MerklePathNode)) -> BitArray {
  case nodes {
    [] -> <<>>
    [_node, ..] -> {
      panic as "Compression of non-empty merkle paths is not yet supported"
    }
  }
}

pub fn deserialize(buf: BitArray) -> Result(#(MerklePath, BitArray), String) {
  case buf {
    <<0, rest:bits>> -> Ok(#(empty(), rest))
    _ ->
      panic as "Deserialization of non-empty merkle paths is not yet supported"
  }
}

pub opaque type MerklePathNode {
  MerklePathNode(hash: BitArray, is_left: Bool)
}
