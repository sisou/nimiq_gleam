import gleam/bit_array
import gleam/bool
import gleam/bytes_builder.{type BytesBuilder}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import utils/serde

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
      use #(length, rest) <- result.try(serde.deserialize_int(buf, 8))

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

pub fn serialize(builder: BytesBuilder, path: MerklePath) -> BytesBuilder {
  builder
  |> bytes_builder.append(<<list.length(path.nodes):8>>)
  |> bytes_builder.append(do_compress(path.nodes, bytes_builder.new(), 0))
  |> bytes_builder.append(
    path.nodes |> list.map(fn(node) { node.hash }) |> bit_array.concat(),
  )
}

pub fn serialize_to_bits(path: MerklePath) -> BitArray {
  bytes_builder.new() |> serialize(path) |> bytes_builder.to_bit_array()
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
  buf: BytesBuilder,
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
      |> bytes_builder.append(<<0:size(num_padding_bits)>>)
      |> bytes_builder.to_bit_array()
    }
    [node, ..rest] -> {
      do_compress(
        rest,
        buf |> bytes_builder.append(<<bool.to_int(node.is_left):1>>),
        count + 1,
      )
    }
  }
}
