import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import nimiq/serde

pub type MerklePath {
  MerklePath(nodes: List(MerklePathNode))
}

pub type MerklePathNode {
  MerklePathNode(hash: BitArray, is_left: Bool)
}

pub fn empty() -> MerklePath {
  MerklePath(nodes: [])
}

pub fn deserialize(buf: BitArray) -> Result(#(MerklePath, BitArray), String) {
  case buf {
    <<0, rest:bits>> -> Ok(#(empty(), rest))
    _ -> {
      use #(length, rest) <- result.try(serde.deserialize_u8(buf))

      let left_bits_byte_size =
        float.ceiling(int.to_float(length) /. 8.0) |> float.round()

      use #(left_bits, rest) <- result.try(case rest {
        <<left_bits:bytes-size(left_bits_byte_size), rest:bits>> ->
          Ok(#(left_bits, rest))
        _ -> Error("Invalid merkle path: out of data")
      })

      use #(nodes, rest) <- result.try(
        deserialize_nodes(rest, left_bits, length, []),
      )

      Ok(#(MerklePath(nodes), rest))
    }
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(MerklePath, String) {
  case deserialize(buf) {
    Ok(#(path, <<>>)) -> Ok(path)
    Ok(_) -> Error("Invalid merkle path: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn serialize(builder: BytesTree, path: MerklePath) -> BytesTree {
  builder
  |> bytes_tree.append(<<list.length(path.nodes):8>>)
  |> bytes_tree.append(do_compress(path.nodes, <<>>, 0))
  |> bytes_tree.append(
    path.nodes |> list.map(fn(node) { node.hash }) |> bit_array.concat(),
  )
}

pub fn serialize_to_bits(path: MerklePath) -> BitArray {
  bytes_tree.new() |> serialize(path) |> bytes_tree.to_bit_array()
}

fn deserialize_nodes(
  buf: BitArray,
  left_bits: BitArray,
  length: Int,
  nodes: List(MerklePathNode),
) -> Result(#(List(MerklePathNode), BitArray), String) {
  case length, buf, left_bits {
    // Return when no more nodes remain to read
    0, <<rest:bits>>, _ -> Ok(#(nodes |> list.reverse(), rest))
    // Read the next 32-byte hash and next left bit
    _, <<hash:bytes-size(32), rest:bits>>, <<is_left:1, rest_left_bits:bits>> ->
      deserialize_nodes(rest, rest_left_bits, length - 1, [
        MerklePathNode(hash:, is_left: is_left == 1),
        ..nodes
      ])
    _, _, _ -> Error("Invalid merkle path: out of data")
  }
}

fn do_compress(
  nodes: List(MerklePathNode),
  buf: BitArray,
  count: Int,
) -> BitArray {
  case nodes {
    [] -> {
      // Add padding to make a full byte
      let num_padding_bits = case count % 8 {
        0 -> 0
        n -> 8 - n
      }
      buf
      |> bit_array.append(<<0:size(num_padding_bits)>>)
    }
    [node, ..rest] -> {
      do_compress(
        rest,
        buf
          |> bit_array.append(<<
            case node.is_left {
              True -> 1
              False -> 0
            }:1,
          >>),
        count + 1,
      )
    }
  }
}
