import blake2b
import gleam/bytes_tree
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result
import iv
import key_nibbles.{type KeyNibbles}
import trie/root_data.{type RootData, RootData}
import trie/trie
import trie/trie_node_child.{type TrieNodeChild, TrieNodeChild}

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

pub type TrieNodeType {
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

pub fn kind(node: TrieNode) -> Option(TrieNodeType) {
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
) -> Result(Int, trie.TrieError) {
  case node.key |> key_nibbles.is_prefix_of(child_prefix) {
    False -> {
      io.println_error(
        "Child's prefix "
        <> child_prefix |> key_nibbles.to_string()
        <> " is not a prefix of the node with key "
        <> node.key |> key_nibbles.to_string()
        <> "!",
      )
      Error(trie.WrongPrefix)
    }
    True -> {
      // Key length has to be smaller or equal to the child prefix length, so this will only panic
      // when `child_prefix` has the same length as `self.key()`.
      // PITODO: return error instead of unwrapping
      case child_prefix |> key_nibbles.get(node.key |> key_nibbles.len()) {
        Some(index) -> Ok(index)
        None -> panic as "Child prefix length is equal to the node key length"
      }
    }
  }
}

/// Returns the current node's child with the given prefix.
pub fn child(
  node: TrieNode,
  child_prefix: KeyNibbles,
) -> Result(TrieNodeChild, trie.TrieError) {
  node
  |> child_index(child_prefix)
  |> result.map(fn(index) {
    case node.children |> iv.get(index) {
      Ok(Some(child)) -> Ok(child)
      _ -> Error(trie.ChildDoesNotExist)
    }
  })
  |> result.flatten()
}

pub fn child_key(
  node: TrieNode,
  child_prefix: KeyNibbles,
) -> Result(KeyNibbles, trie.TrieError) {
  node
  |> child(child_prefix)
  |> result.map(fn(child) { child |> trie_node_child.key(node.key) })
}

/// Sets the current node's child with the given prefix.
pub fn put_child(
  node: TrieNode,
  child_key: KeyNibbles,
  child_hash: BitArray,
) -> Result(TrieNode, trie.TrieError) {
  use idx <- result.try(node |> child_index(child_key))
  let suffix = child_key |> key_nibbles.suffix(node.key |> key_nibbles.len())
  node.children
  |> iv.set(idx, Some(TrieNodeChild(suffix:, hash: child_hash)))
  |> result.map(fn(children) { TrieNode(..node, children:) })
  |> result.replace_error(trie.ChildDoesNotExist)
}

pub fn put_child_no_hash(
  node: TrieNode,
  child_key: KeyNibbles,
) -> Result(TrieNode, trie.TrieError) {
  node |> put_child(child_key, <<>>)
}

/// Removes the current node's child with the given prefix.
pub fn remove_child(
  node: TrieNode,
  child_prefix: KeyNibbles,
) -> Result(TrieNode, trie.TrieError) {
  use idx <- result.try(node |> child_index(child_prefix))
  node.children
  |> iv.set(idx, None)
  |> result.map(fn(children) { TrieNode(..node, children:) })
  |> result.replace_error(trie.ChildDoesNotExist)
}

pub fn put_value(
  node: TrieNode,
  value: BitArray,
) -> Result(TrieNode, trie.TrieError) {
  case is_root(node) {
    True -> Error(trie.RootCantHaveValue)
    False -> TrieNode(..node, value: Some(value)) |> Ok
  }
}

pub fn iter_children(node: TrieNode) -> iv.Array(TrieNodeChild) {
  node.children
  |> iv.filter(fn(child) { child |> option.is_some() })
  |> iv.map(fn(child) {
    case child {
      Some(child) -> child
      None -> panic as "Child cannot not be None"
    }
  })
}

fn can_hash(node: TrieNode) -> Bool {
  node
  |> iter_children()
  |> iv.all(fn(child) { child |> trie_node_child.has_hash() })
}

pub fn hash(node: TrieNode) -> Option(BitArray) {
  case can_hash(node) {
    True -> {
      let hasher = bytes_tree.new()
      let hasher =
        hasher |> bytes_tree.append_tree(node.key |> key_nibbles.serialize())
      let hasher = case has_children(node), node.value {
        _, None -> hasher |> bytes_tree.append(<<0>>)
        False, Some(val) -> {
          let hasher = hasher |> bytes_tree.append(<<1>>)
          hasher |> bytes_tree.append(val)
        }
        True, Some(val) -> {
          let hasher = hasher |> bytes_tree.append(<<2>>)
          let val_hash = val |> blake2b.hash()
          hasher |> bytes_tree.append(val_hash)
        }
      }
      // Serialize children
      let hasher =
        node.children
        |> iv.fold(hasher, fn(acc, child) {
          case child {
            Some(child) -> {
              let acc = acc |> bytes_tree.append(<<1>>)
              acc
              |> bytes_tree.append_tree(child |> trie_node_child.serialize())
            }
            None -> acc |> bytes_tree.append(<<0>>)
          }
        })
      Some(blake2b.hash(hasher |> bytes_tree.to_bit_array()))
    }
    False -> None
  }
}

pub fn hash_assert(node: TrieNode) -> BitArray {
  case hash(node) {
    Some(hash) -> hash
    None ->
      panic as "can only hash TrieNode with complete information about children"
  }
}
