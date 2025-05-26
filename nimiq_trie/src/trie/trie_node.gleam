import gleam/bytes_tree.{type BytesTree}
import gleam/int
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result

import iv

import blake2b
import key_nibbles.{type KeyNibbles}
import trie/root_data.{type RootData, RootData}
import trie/trie_error.{type TrieError}
import trie/trie_node_child.{type TrieNodeChild, TrieNodeChild}
import utils/serde

fn no_children() -> iv.Array(Option(TrieNodeChild)) {
  iv.repeat(None, 16)
}

/// A struct representing a node in the Merkle Radix Trie. It can be either a branch node, which has
/// only references to its children, a leaf node, which contains a value or a hybrid node, which has
/// both children and a value. A branch/hybrid node can have up to 16 children, since we represent
/// the keys in hexadecimal form, each child represents a different hexadecimal character.
pub type TrieNode {
  TrieNode(
    // This is not serialized.
    key: KeyNibbles,
    // The root data is not included when the `TrieNode` is hashed.
    root_data: Option(RootData),
    value: Option(BitArray),
    children: iv.Array(Option(TrieNodeChild)),
  )
}

pub type TrieNodeKind {
  Root
  Branch
  Hybrid
  Leaf
}

/// Creates a new leaf node.
pub fn new_leaf(key: KeyNibbles, value: BitArray) -> TrieNode {
  TrieNode(key:, root_data: None, value: Some(value), children: no_children())
}

/// Creates an empty root node
pub fn new_root() -> TrieNode {
  TrieNode(
    key: key_nibbles.root(),
    root_data: Some(RootData(num_branches: 0, num_hybrids: 0, num_leaves: 0)),
    value: None,
    children: no_children(),
  )
}

/// Creates a new empty branch node.
pub fn new_empty(key: KeyNibbles) -> TrieNode {
  TrieNode(key:, root_data: None, value: None, children: no_children())
}

pub fn is_empty(node: TrieNode) -> Bool {
  !is_root(node) && option.is_none(node.value) && !has_children(node)
}

pub fn is_root(node: TrieNode) -> Bool {
  option.is_some(node.root_data)
}

pub fn is_hybrid(node: TrieNode) -> Bool {
  !is_root(node) && option.is_some(node.value) && has_children(node)
}

pub fn has_children(node: TrieNode) -> Bool {
  node.children
  |> iv.any(fn(child) { child |> option.is_some() })
}

pub fn kind(node: TrieNode) -> Option(TrieNodeKind) {
  case is_root(node), has_children(node), option.is_some(node.value) {
    False, False, False -> None
    False, False, True -> Some(Leaf)
    False, True, False -> Some(Branch)
    False, True, True -> Some(Hybrid)
    True, _, _ -> Some(Root)
  }
}

/// Returns the child index of the given prefix in the current node. If the current node has the
/// key "31f6d" and the given child key is "31f6d925ca" (both are in hexadecimal) then the child
/// index is 9.
pub fn child_index(
  node: TrieNode,
  child_prefix: KeyNibbles,
) -> Result(Int, TrieError) {
  case node.key |> key_nibbles.is_prefix_of(child_prefix) {
    False -> {
      io.println_error(
        "Child's prefix "
        <> child_prefix |> key_nibbles.to_string()
        <> " is not a prefix of the node with key "
        <> node.key |> key_nibbles.to_string()
        <> "!",
      )
      Error(trie_error.WrongPrefix)
    }
    True -> {
      // Key length has to be smaller or equal to the child prefix length, so this will only panic
      // when `child_prefix` has the same length as `self.key()`.
      // PITODO: return error instead of unwrapping
      let assert Some(index) =
        child_prefix |> key_nibbles.get(node.key |> key_nibbles.len())
        as "Child prefix length is equal to the node key length"
      Ok(index)
    }
  }
}

/// Returns the current node's child with the given prefix.
pub fn child(
  node: TrieNode,
  child_prefix: KeyNibbles,
) -> Result(TrieNodeChild, TrieError) {
  node
  |> child_index(child_prefix)
  |> result.map(fn(index) {
    case node.children |> iv.get(index) {
      Ok(Some(child)) -> Ok(child)
      _ -> Error(trie_error.ChildDoesNotExist)
    }
  })
  |> result.flatten()
}

pub fn child_key(
  node: TrieNode,
  child_prefix: KeyNibbles,
) -> Result(KeyNibbles, TrieError) {
  node
  |> child(child_prefix)
  |> result.map(fn(child) { child |> trie_node_child.key(node.key) })
}

/// Sets the current node's child with the given prefix.
pub fn put_child(
  node: TrieNode,
  child_key: KeyNibbles,
  child_hash: BitArray,
) -> Result(TrieNode, TrieError) {
  use idx <- result.try(node |> child_index(child_key))
  let suffix = child_key |> key_nibbles.suffix(node.key |> key_nibbles.len())
  node.children
  |> iv.set(idx, Some(TrieNodeChild(suffix:, hash: child_hash)))
  |> result.map(fn(children) { TrieNode(..node, children:) })
  |> result.replace_error(trie_error.ChildDoesNotExist)
}

pub fn put_child_no_hash(
  node: TrieNode,
  child_key: KeyNibbles,
) -> Result(TrieNode, TrieError) {
  node |> put_child(child_key, blake2b.default)
}

/// Removes the current node's child with the given prefix.
pub fn remove_child(
  node: TrieNode,
  child_prefix: KeyNibbles,
) -> Result(TrieNode, TrieError) {
  use idx <- result.try(node |> child_index(child_prefix))
  node.children
  |> iv.set(idx, None)
  |> result.map(fn(children) { TrieNode(..node, children:) })
  |> result.replace_error(trie_error.ChildDoesNotExist)
}

pub fn put_value(
  node: TrieNode,
  value: BitArray,
) -> Result(#(TrieNode, Option(BitArray)), TrieError) {
  case is_root(node) {
    True -> Error(trie_error.RootCantHaveValue)
    False -> #(TrieNode(..node, value: Some(value)), node.value) |> Ok
  }
}

pub fn take_value(node: TrieNode) -> #(TrieNode, Option(BitArray)) {
  #(TrieNode(..node, value: None), node.value)
}

pub fn iter_children(node: TrieNode) -> iv.Array(TrieNodeChild) {
  node.children |> iv.filter_map(option.to_result(_, Nil))
}

fn can_hash(node: TrieNode) -> Bool {
  node
  |> iter_children()
  |> iv.all(fn(child) { child |> trie_node_child.has_hash() })
}

pub fn hash(node: TrieNode) -> Option(BitArray) {
  case can_hash(node) {
    True -> {
      let hasher =
        bytes_tree.new()
        |> key_nibbles.serialize(node.key)
      let hasher =
        case has_children(node), node.value {
          _, None -> hasher |> serde.serialize_u8(0)
          False, Some(val) -> {
            hasher
            |> serde.serialize_u8(1)
            |> serde.serialize_bytes(val)
          }
          True, Some(val) -> {
            let val_hash = val |> blake2b.hash()
            hasher
            |> serde.serialize_u8(2)
            |> serde.serialize_bitarray(val_hash)
          }
        }
        |> serialize_children(node.children)

      Some(hasher |> bytes_tree.to_bit_array() |> blake2b.hash())
    }
    False -> None
  }
}

pub fn hash_assert(node: TrieNode) -> BitArray {
  let assert Some(hash) = hash(node)
    as "can only hash TrieNode with complete information about children"
  hash
}

pub fn serialize(to buf: BytesTree, node node: TrieNode) -> BytesTree {
  let has_root_data = is_root(node)
  let has_value = option.is_some(node.value)
  let flags =
    0
    |> int.bitwise_or(case has_root_data {
      True -> 0b01
      False -> 0
    })
    |> int.bitwise_or(case has_value {
      True -> 0b10
      False -> 0
    })
  let child_count =
    node.children
    |> iv.fold(0, fn(acc, child) {
      case child {
        Some(_) -> acc + 1
        None -> acc
      }
    })

  buf
  |> serde.serialize_u8(flags)
  |> bytes_tree.append_tree(case node.root_data {
    Some(data) ->
      bytes_tree.new()
      |> serde.serialize_u8(1)
      |> root_data.serialize(data)
    None -> bytes_tree.new() |> serde.serialize_u8(0)
  })
  |> bytes_tree.append_tree(case node.value {
    Some(value) ->
      bytes_tree.new()
      |> serde.serialize_u8(1)
      |> serde.serialize_bytes(value)
    None -> bytes_tree.new() |> serde.serialize_u8(0)
  })
  |> serde.serialize_u8(child_count)
  |> serialize_children(node.children)
}

fn serialize_children(
  buf: BytesTree,
  children: iv.Array(Option(TrieNodeChild)),
) -> BytesTree {
  children
  |> iv.fold(buf, fn(acc, child) {
    case child {
      Some(child) -> {
        acc
        |> serde.serialize_u8(1)
        |> trie_node_child.serialize(child)
      }
      None -> acc |> serde.serialize_u8(0)
    }
  })
}

pub fn serialize_to_vec(node: TrieNode) -> BitArray {
  bytes_tree.new() |> serialize(node) |> bytes_tree.to_bit_array()
}

pub fn deserialize(buf: BitArray) -> Result(#(TrieNode, BitArray), String) {
  use #(flags, rest) <- result.try(serde.deserialize_u8(buf))
  let has_root_data = flags |> int.bitwise_and(0b01) != 0
  let has_value = flags |> int.bitwise_and(0b10) != 0
  use #(root_data, rest) <- result.try(deserialize_root_data(rest))
  use _ <- result.try(verify_root_data_flag(has_root_data, root_data))
  use #(value, rest) <- result.try(deserialize_value(rest))
  use _ <- result.try(verify_value_flag(has_value, value))
  use #(exp_child_count, rest) <- result.try(serde.deserialize_u8(rest))
  use #(children, rest) <- result.try(deserialize_children(rest))
  let child_count =
    children
    |> iv.fold(0, fn(acc, child) {
      case child {
        Some(_) -> acc + 1
        None -> acc
      }
    })
  use _ <- result.try(verify_children_length(exp_child_count, child_count))

  Ok(#(
    TrieNode(
      // Make it clear that the key needs to be changed after deserialization.
      key: key_nibbles.badbadbad(),
      root_data:,
      value:,
      children:,
    ),
    rest,
  ))
}

fn deserialize_root_data(
  buf: BitArray,
) -> Result(#(Option(RootData), BitArray), String) {
  use #(root_data_option, rest) <- result.try(serde.deserialize_u8(buf))
  case root_data_option {
    1 -> {
      use #(root_data, rest) <- result.try(root_data.deserialize(rest))
      Ok(#(Some(root_data), rest))
    }
    0 -> Ok(#(None, rest))
    _ -> panic as "Invalid root data option type"
  }
}

fn verify_root_data_flag(
  has_root_data: Bool,
  root_data: Option(RootData),
) -> Result(Nil, String) {
  case has_root_data == option.is_some(root_data) {
    True -> Ok(Nil)
    False -> Error("Flags mismatch for root data")
  }
}

fn deserialize_value(
  buf: BitArray,
) -> Result(#(Option(BitArray), BitArray), String) {
  use #(value_option, rest) <- result.try(serde.deserialize_u8(buf))
  case value_option {
    1 -> {
      use #(value, rest) <- result.try(serde.deserialize_bytes(rest))
      Ok(#(Some(value), rest))
    }
    0 -> Ok(#(None, rest))
    _ -> panic as "Invalid value option type"
  }
}

fn verify_value_flag(
  has_value: Bool,
  value: Option(BitArray),
) -> Result(Nil, String) {
  case has_value == option.is_some(value) {
    True -> Ok(Nil)
    False -> Error("Flags mismatch for value")
  }
}

fn deserialize_children(
  buf: BitArray,
) -> Result(#(iv.Array(Option(TrieNodeChild)), BitArray), String) {
  deserialize_child(iv.new(), 0, buf)
}

fn deserialize_child(
  children: iv.Array(Option(TrieNodeChild)),
  idx: Int,
  buf: BitArray,
) -> Result(#(iv.Array(Option(TrieNodeChild)), BitArray), String) {
  case idx {
    16 -> Ok(#(children, buf))
    _ -> {
      use #(child_option, rest) <- result.try(serde.deserialize_u8(buf))
      case child_option {
        1 -> {
          use #(child, rest) <- result.try(trie_node_child.deserialize(rest))
          deserialize_child(children |> iv.append(Some(child)), idx + 1, rest)
        }
        0 -> deserialize_child(children |> iv.append(None), idx + 1, rest)
        _ -> panic as "Invalid child option type"
      }
    }
  }
}

fn verify_children_length(
  exp_child_count: Int,
  child_count: Int,
) -> Result(Nil, String) {
  case exp_child_count == child_count {
    True -> Ok(Nil)
    False -> Error("Unexpected number of children")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(TrieNode, String) {
  case deserialize(buf) {
    Ok(#(node, <<>>)) -> Ok(node)
    Ok(_) -> Error("Invalid TrieNode: trailing bytes")
    Error(err) -> Error(err)
  }
}
