import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/result
import key_nibbles.{type KeyNibbles}
import utils/serde

/// A struct representing the child of a node. It just contains the child's suffix (the part of the
/// child's key that is different from its parent) and its hash.
pub type TrieNodeChild {
  TrieNodeChild(
    /// The suffix of this child.
    suffix: KeyNibbles,
    /// An empty bit array (the `<<>>` value) marks an uncomputed child hash.
    hash: BitArray,
  )
}

pub fn has_hash(child: TrieNodeChild) -> Bool {
  child.hash |> bit_array.bit_size() > 0
}

pub fn key(child: TrieNodeChild, parent_key: KeyNibbles) -> KeyNibbles {
  parent_key |> key_nibbles.add(child.suffix)
}

pub fn serialize(to buf: BytesTree, child child: TrieNodeChild) -> BytesTree {
  buf
  |> key_nibbles.serialize(child.suffix)
  |> bytes_tree.append(child.hash)
}

pub fn serialize_to_vec(child: TrieNodeChild) -> BitArray {
  bytes_tree.new() |> serialize(child) |> bytes_tree.to_bit_array()
}

pub fn deserialize(buf: BitArray) -> Result(#(TrieNodeChild, BitArray), String) {
  use #(suffix, rest) <- result.try(key_nibbles.deserialize(buf))
  use #(hash, rest) <- result.try(serde.deserialize_bitarray(rest, 32))
  Ok(#(TrieNodeChild(suffix, hash), rest))
}

pub fn deserialize_all(buf: BitArray) -> Result(TrieNodeChild, String) {
  case deserialize(buf) {
    Ok(#(child, <<>>)) -> Ok(child)
    Ok(_) -> Error("Invalid TrieNodeChild: trailing bytes")
    Error(err) -> Error(err)
  }
}
