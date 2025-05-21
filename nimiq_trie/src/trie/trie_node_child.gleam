import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import key_nibbles.{type KeyNibbles}

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

pub fn serialize(child: TrieNodeChild) -> BytesTree {
  bytes_tree.new()
  |> bytes_tree.append_tree(child.suffix |> key_nibbles.serialize())
  |> bytes_tree.append(child.hash)
}

pub fn serialize_to_vec(child: TrieNodeChild) -> BitArray {
  child |> serialize() |> bytes_tree.to_bit_array()
}
