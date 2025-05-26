import gleam/bool
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import iv

import key_nibbles.{type KeyNibbles}
import trie/count_updates.{type CountUpdates, CountUpdates}
import trie/trie_item.{type TrieItem}
import trie/trie_node.{type TrieNode, TrieNode}
import trie/trie_node_child.{TrieNodeChild}

// import trie/trie_chunk.{type TrieChunk, type TrieChunkPushResult}
// import trie/trie_proof.{type TrieProof}
// import trie/trie_proof_node.{type TrieProofNode}

pub type MerkleRadixTrie(data) {
  MerkleRadixTrie(
    table: Dict(BitArray, BitArray),
    serializer: fn(data) -> BitArray,
    deserializer: fn(BitArray) -> data,
  )
}

/// Start a new Merkle Radix Trie
pub fn new(
  serializer serializer: fn(data) -> BitArray,
  deserializer deserializer: fn(BitArray) -> data,
) -> MerkleRadixTrie(data) {
  MerkleRadixTrie(table: dict.new(), deserializer:, serializer:) |> init_root()
}

fn init_root(trie: MerkleRadixTrie(data)) -> MerkleRadixTrie(data) {
  case trie |> get_root() {
    // Root already exists
    Some(_) -> trie
    None -> {
      let root = trie_node.new_root()
      trie |> put_node(root)
    }
  }
}

pub fn init(
  trie: MerkleRadixTrie(data),
  values: List(TrieItem),
) -> MerkleRadixTrie(data) {
  // let assert True = trie |> is_complete()
  let assert 0 = trie |> num_leaves()
  let assert 0 = trie |> num_hybrids()

  values
  |> list.fold(trie, fn(trie, pair) {
    let #(key, value) = pair
    trie |> put_raw(key, value)
  })

  trie |> update_root()
}

/// Prints a human friendly version of the subtrie for debugging.
/// Not to be used on large trees!
pub fn debug_print(trie: MerkleRadixTrie(data)) {
  io.println("-> ROOT")
  trie |> debug_print_subtrie(key_nibbles.root(), 2)
}

/// Prints a human friendly version of the subtrie for debugging.
/// Not to be used on large trees!
pub fn debug_print_subtrie(
  trie: MerkleRadixTrie(data),
  key: KeyNibbles,
  depth: Int,
) {
  let prefix = "  " |> string.repeat(depth)
  case trie |> get_node(key) {
    Some(node) -> {
      // io.println(
      //   prefix
      //   <> "   ["
      //   <> node
      //   |> trie_node.hash_assert()
      //   |> bit_array.base16_encode()
      //   |> string.lowercase()
      //   <> "]",
      // )
      node
      |> trie_node.iter_children()
      |> iv.each(fn(child) {
        io.println(
          prefix
          <> "-> "
          <> child.suffix |> key_nibbles.to_string()
          <> " ("
          <> child |> trie_node_child.has_hash() |> bool.to_string()
          <> ")",
        )
        let subkey = child |> trie_node_child.key(key)
        debug_print_subtrie(trie, subkey, depth + 2)
      })
    }
    None -> {
      io.println(prefix <> "-> MISSING")
    }
  }
}

/// Returns the root hash of the Merkle Radix Trie.
pub fn root_hash_assert(trie: MerkleRadixTrie(data)) -> BitArray {
  let assert Some(root) = trie |> get_root()
  root |> trie_node.hash_assert()
}

/// Returns the root hash of the Merkle Radix Trie if the trie is complete.
pub fn root_hash(trie: MerkleRadixTrie(data)) -> Option(BitArray) {
  let assert Some(root) = trie |> get_root()
  root |> trie_node.hash()
}

// pub fn is_complete(trie: MerkleRadixTrie(data)) -> Bool {
//   let assert Some(root) = trie |> get_root()
//   let assert Some(root_data) = root.root_data
//   root_data.incomplete_from |> option.is_none()
// }

pub fn num_branches(trie: MerkleRadixTrie(data)) -> Int {
  let assert Some(root) = trie |> get_root()
  let assert Some(root_data) = root.root_data
  root_data.num_branches
}

pub fn num_hybrids(trie: MerkleRadixTrie(data)) -> Int {
  let assert Some(root) = trie |> get_root()
  let assert Some(root_data) = root.root_data
  root_data.num_hybrids
}

pub fn num_leaves(trie: MerkleRadixTrie(data)) -> Int {
  let assert Some(root) = trie |> get_root()
  let assert Some(root_data) = root.root_data
  root_data.num_leaves
}

pub fn count_nodes(trie: MerkleRadixTrie(data)) -> #(Int, Int, Int) {
  let count_branches = 0
  let count_hybrids = 0
  let count_leaves = 0

  let assert Some(root) = trie |> get_root()
    as "The Merkle Radix Trie didn't have a root node!"
  let stack = [root]

  let #(count_branches, count_hybrids, count_leaves) =
    trie
    |> count_nodes_while(stack, count_branches, count_hybrids, count_leaves)

  let assert True =
    #(count_branches, count_hybrids, count_leaves)
    == #(trie |> num_branches(), trie |> num_hybrids(), trie |> num_leaves())

  #(count_branches, count_hybrids, count_leaves)
}

fn count_nodes_while(
  trie: MerkleRadixTrie(data),
  stack: List(TrieNode),
  num_branches: Int,
  num_hybrids: Int,
  num_leaves: Int,
) -> #(Int, Int, Int) {
  case stack {
    [] -> #(num_branches, num_hybrids, num_leaves)
    [item, ..stack] -> {
      let stack =
        item
        |> trie_node.iter_children()
        |> iv.fold(stack, fn(stack, child) {
          let child_key = child |> trie_node_child.key(item.key)
          let assert Some(child) = trie |> get_node(child_key)
            as "Failed to find the child of a Merkle Radix Trie node. The database must be corrupt!"
          [child, ..stack]
        })
      case item |> trie_node.kind() {
        None -> panic as "Empty nodes mustn't exist in the database"
        Some(trie_node.Root) -> {
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
        Some(trie_node.Branch) -> {
          let num_branches = num_branches + 1
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
        Some(trie_node.Hybrid) -> {
          let num_hybrids = num_hybrids + 1
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
        Some(trie_node.Leaf) -> {
          let num_leaves = num_leaves + 1
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
      }
    }
  }
}

fn get_node(trie: MerkleRadixTrie(data), key: KeyNibbles) -> Option(TrieNode) {
  trie.table
  |> dict.get(key |> key_nibbles.serialize_to_vec())
  |> result.replace_error(
    "Node not found for key " <> key |> key_nibbles.to_string(),
  )
  |> result.map(trie_node.deserialize_all)
  |> result.flatten()
  |> result.map(fn(node) { TrieNode(..node, key: key) })
  |> option.from_result()
}

fn put_node(
  trie: MerkleRadixTrie(data),
  node: TrieNode,
) -> MerkleRadixTrie(data) {
  let table =
    trie.table
    |> dict.insert(
      node.key |> key_nibbles.serialize_to_vec(),
      node |> trie_node.serialize_to_vec(),
    )
  MerkleRadixTrie(..trie, table:)
}

fn remove_node(
  trie: MerkleRadixTrie(data),
  key: KeyNibbles,
) -> MerkleRadixTrie(data) {
  let table = trie.table |> dict.delete(key |> key_nibbles.serialize_to_vec())
  MerkleRadixTrie(..trie, table:)
}

/// Get the value at the given key. If there's no leaf or hybrid node at the given key then it
/// returns None.
pub fn get(trie: MerkleRadixTrie(data), key key: KeyNibbles) -> Option(data) {
  get_raw(trie, key) |> option.map(trie.deserializer)
}

fn get_raw(trie: MerkleRadixTrie(data), key: KeyNibbles) -> Option(BitArray) {
  trie
  |> get_node(key)
  |> option.map(fn(node) { node.value })
  |> option.flatten()
}

/// Insert a value into the Merkle Radix Trie at the given key. If the key already exists then
/// it will overwrite it. You can't use this function to check the existence of a given key.
pub fn put(
  trie: MerkleRadixTrie(data),
  key key: KeyNibbles,
  value value: data,
) -> MerkleRadixTrie(data) {
  trie |> put_raw(key, value |> trie.serializer)
}

/// Insert a value into the Merkle Radix Trie at the given key. If the key already exists then
/// it will overwrite it. You can't use this function to check the existence of a given key.
fn put_raw(
  trie: MerkleRadixTrie(data),
  key: KeyNibbles,
  value: BitArray,
) -> MerkleRadixTrie(data) {
  // Start by getting the root node.
  let assert Some(cur_node) = trie |> get_root()
    as "Merkle Radix Trie must have a root node!"

  // And initialize the root path.
  let root_path: List(TrieNode) = list.new()

  let #(trie, root_path, count_updates) =
    trie |> put_raw_loop(cur_node, root_path, key, value)

  trie |> update_keys(root_path, count_updates)
}

fn put_raw_loop(
  trie: MerkleRadixTrie(data),
  cur_node: TrieNode,
  root_path: List(TrieNode),
  key: KeyNibbles,
  value: BitArray,
) -> #(MerkleRadixTrie(data), List(TrieNode), CountUpdates) {
  case cur_node.key |> key_nibbles.is_prefix_of(key) {
    // If the current node key is no longer a prefix for the given key then we need to
    // split the node.
    False -> {
      // Check if the new node is a sibling or the parent of cur_node.
      let #(trie, root_path, count_updates) = case
        key |> key_nibbles.is_prefix_of(cur_node.key)
      {
        True -> {
          // The new node is the parent of the current node. Thus it needs to be a hybrid node.
          let assert Ok(new_node) =
            trie_node.new_leaf(key, value)
            |> trie_node.put_child_no_hash(cur_node.key)
          let trie = trie |> put_node(new_node)

          // Push the new node into the root path.
          let root_path = root_path |> list.append([new_node])
          let count_updates =
            CountUpdates(..count_updates.default(), hybrids: 1)
          #(trie, root_path, count_updates)
        }
        False -> {
          // The new node is a sibling of the current node. Thus it is a leaf node.
          let new_node = trie_node.new_leaf(key, value)
          let trie = trie |> put_node(new_node)

          // We insert a new branch node as the parent of both the current node and the
          // new node.
          let assert Ok(new_parent) =
            trie_node.new_empty(cur_node.key |> key_nibbles.common_prefix(key))
            |> trie_node.put_child_no_hash(cur_node.key)
            |> result.map(fn(new_parent) {
              new_parent
              |> trie_node.put_child(
                new_node.key,
                new_node |> trie_node.hash_assert(),
              )
            })
            |> result.flatten()
          let trie = trie |> put_node(new_parent)

          let count_updates =
            CountUpdates(..count_updates.default(), branches: 1, leaves: 1)
          // Push the parent node into the root path.
          let root_path = root_path |> list.append([new_parent])
          #(trie, root_path, count_updates)
        }
      }
      // break
      #(trie, root_path, count_updates)
    }
    True -> {
      // If the current node key is equal to the given key, we have found an existing node
      // with the given key. Update the value.
      case cur_node.key |> key_nibbles.equals(key) {
        True -> {
          // Update the node and store it.
          let prev_kind = cur_node |> trie_node.kind()
          let assert Ok(#(cur_node, _old_value)) =
            cur_node |> trie_node.put_value(value)
          let trie = trie |> put_node(cur_node)

          let count_updates =
            count_updates.from_update(prev_kind, cur_node |> trie_node.kind())
          // Push the node into the root path.
          let root_path = root_path |> list.append([cur_node])
          // break
          #(trie, root_path, count_updates)
        }
        False -> {
          // Try to find a child of the current node that matches our key.
          case cur_node |> trie_node.child_key(key) {
            // If no matching child exists, add a new child to the current node.
            Error(_) -> {
              // Create and store the new node.
              let new_node = trie_node.new_leaf(key, value)
              let trie = trie |> put_node(new_node)

              // Update the parent node and store it.
              let old_kind = cur_node |> trie_node.kind()
              let assert Ok(cur_node) =
                cur_node
                |> trie_node.put_child(
                  new_node.key,
                  new_node |> trie_node.hash_assert(),
                )
              let trie = trie |> put_node(cur_node)

              let count_updates =
                CountUpdates(..count_updates.default(), leaves: 1)
                |> count_updates.apply_update(
                  old_kind,
                  cur_node |> trie_node.kind(),
                )
              // Push the parent node into the root path.
              let root_path = root_path |> list.append([cur_node])
              // break
              #(trie, root_path, count_updates)
            }
            // If there's a child, then we update the current node and the root path, and
            // continue down the trie.
            Ok(child_key) -> {
              let root_path = root_path |> list.append([cur_node])

              let assert Some(cur_node) = trie |> get_node(child_key)

              put_raw_loop(trie, cur_node, root_path, key, value)
            }
          }
        }
      }
    }
  }
}

/// Removes the value in the Merkle Radix Trie at the given key. If the key doesn't exist
/// then this function just returns silently. You can't use this to check the existence of a
/// given prefix.
pub fn remove(
  trie: MerkleRadixTrie(data),
  key: KeyNibbles,
) -> MerkleRadixTrie(data) {
  trie |> remove_raw(key)
}

/// Removes the value in the Merkle Radix Trie at the given key. If the key doesn't exist
/// then this function just returns silently. You can't use this to check the existence of a
/// given prefix.
fn remove_raw(
  trie: MerkleRadixTrie(data),
  key: KeyNibbles,
) -> MerkleRadixTrie(data) {
  // Start by getting the root node.
  let assert Some(cur_node) = trie |> get_root()
    as "Merkle Radix Trie must have a root node!"

  // And initialize the root path.
  let root_path: List(TrieNode) = list.new()

  // Go down the trie until you find the key.
  let #(trie, root_path, should_continue) =
    trie |> remove_raw_loop(cur_node, root_path, key)

  case should_continue {
    False -> {
      // The loop `return`ed
      trie
    }
    True -> {
      // The loop `break`ed

      // Walk along the root path towards the root node, starting with the immediate predecessor
      // of the node with the given key, and update the nodes along the way.
      let child_key = key
      let count_updates = CountUpdates(..count_updates.default(), leaves: -1)

      remove_raw_while(
        trie,
        root_path |> list.reverse(),
        child_key,
        count_updates,
      )
    }
  }
}

fn remove_raw_loop(
  trie: MerkleRadixTrie(data),
  cur_node: TrieNode,
  root_path: List(TrieNode),
  key: KeyNibbles,
) -> #(MerkleRadixTrie(data), List(TrieNode), Bool) {
  case cur_node.key |> key_nibbles.is_prefix_of(key) {
    False -> {
      // If the current node key is no longer a prefix for the given key then the key doesn't
      // exist and we stop here.
      // return
      #(trie, root_path, False)
    }
    True -> {
      // If the current node key is equal to our given key, we have found our node.
      // Update/remove the node.
      case cur_node.key |> key_nibbles.equals(key) {
        True -> {
          // Remove the value from the node.
          let prev_kind = cur_node |> trie_node.kind()
          let #(cur_node, _old_value) = cur_node |> trie_node.take_value()

          case
            cur_node |> trie_node.is_root()
            || cur_node |> trie_node.has_children()
          {
            True -> {
              // Node was a hybrid node and is now a branch node.
              let num_children =
                cur_node |> trie_node.iter_children() |> iv.length()

              // If it has only a single child and isn't the root node, merge it with that child.
              let #(trie, root_path, count_updates) = case
                num_children == 1 && !{ cur_node |> trie_node.is_root() }
              {
                True -> {
                  // Remove the node from the database.
                  let trie = trie |> remove_node(cur_node.key)

                  // Get the node's only child and add it to the root path.
                  let assert Ok(only_child_key) =
                    cur_node
                    |> trie_node.iter_children()
                    |> iv.first()
                    |> result.map(fn(child) {
                      child |> trie_node_child.key(cur_node.key)
                    })

                  let assert Some(only_child) = trie |> get_node(only_child_key)

                  let root_path = root_path |> list.append([only_child])

                  // We removed a hybrid node.
                  let count_updates =
                    CountUpdates(..count_updates.default(), hybrids: -1)

                  #(trie, root_path, count_updates)
                }
                False -> {
                  // The node is root or has multiple children, thus we cannot remove it.
                  // Instead we converted it to a branch node by removing its value.

                  // We converted a hybrid node into a branch node.
                  // Or kept a branch node a branch node if there was no value stored before.
                  let count_updates =
                    count_updates.from_update(
                      prev_kind,
                      cur_node |> trie_node.kind(),
                    )

                  // Update the node and add it to the root path.
                  let trie = trie |> put_node(cur_node)

                  let root_path = root_path |> list.append([cur_node])

                  #(trie, root_path, count_updates)
                }
              }
              // Update the keys and hashes of the rest of the root path.
              let trie = trie |> update_keys(root_path, count_updates)
              // return
              #(trie, root_path, False)
            }
            False -> {
              // Node was a leaf node, delete if from the database.
              let trie = trie |> remove_node(key)
              // break
              #(trie, root_path, True)
            }
          }
        }
        False -> {
          // Try to find a child of the current node that matches our key.
          case cur_node |> trie_node.child_key(key) {
            // If no matching child exists, then the key doesn't exist and we stop here.
            Error(_) -> {
              // return
              #(trie, root_path, False)
            }
            // If there's a child, then we update the current node and the root path, and
            // continue down the trie.
            Ok(child_key) -> {
              let root_path = root_path |> list.append([cur_node])

              let assert Some(cur_node) = trie |> get_node(child_key)

              remove_raw_loop(trie, cur_node, root_path, key)
            }
          }
        }
      }
    }
  }
}

// remove_raw_while(trie, root_path |> list.reverse(), child_key, count_updates)
fn remove_raw_while(
  trie: MerkleRadixTrie(data),
  root_path_reversed: List(TrieNode),
  child_key: KeyNibbles,
  count_updates: CountUpdates,
) -> MerkleRadixTrie(data) {
  case root_path_reversed {
    [] -> {
      trie
    }
    [parent_node, ..root_path_reversed] -> {
      // Remove the child from the parent node.
      let prev_parent_kind = parent_node |> trie_node.kind()
      let assert Ok(parent_node) =
        parent_node |> trie_node.remove_child(child_key)
      let count_updates =
        count_updates
        |> count_updates.apply_update(
          prev_parent_kind,
          parent_node |> trie_node.kind(),
        )

      // Get the number of children of the node.
      let num_children = parent_node |> trie_node.iter_children() |> iv.length()

      // If the node has only a single child (and it isn't the root node), merge it with the
      // child.
      case
        num_children == 1
        && !{ parent_node |> trie_node.is_root() }
        && !{ parent_node |> trie_node.is_hybrid() }
      {
        True -> {
          // Remove the node from the database.
          let trie = trie |> remove_node(parent_node.key)
          let count_updates =
            count_updates
            |> count_updates.apply_update(parent_node |> trie_node.kind(), None)

          // Get the node's only child and add it to the root path.
          let assert Ok(only_child_key) =
            parent_node
            |> trie_node.iter_children()
            |> iv.first()
            |> result.map(fn(child) {
              child |> trie_node_child.key(parent_node.key)
            })

          let assert Some(only_child) = trie |> get_node(only_child_key)

          let root_path_reversed = [only_child, ..root_path_reversed]

          // Update the keys and hashes of the rest of the root path.
          let trie =
            trie
            |> update_keys(root_path_reversed |> list.reverse(), count_updates)

          // return
          trie
        }
        False -> {
          case parent_node |> trie_node.is_empty() {
            // If the node has any children, or it is either the root or a hybrid node, we just store the
            // parent node in the database and the root path. Then we update the keys and hashes of
            // of the root path.
            False -> {
              let trie = trie |> put_node(parent_node)

              let root_path_reversed = [parent_node, ..root_path_reversed]

              // Update the keys and hashes of the rest of the root path.
              let trie =
                trie
                |> update_keys(
                  root_path_reversed |> list.reverse(),
                  count_updates,
                )

              // return
              trie
            }
            // Otherwise, our node must have no children and not be the root/hybrid node. In this case we
            // need to remove it too, so we loop again.
            True -> {
              let trie = trie |> remove_node(parent_node.key)
              let count_updates =
                count_updates
                |> count_updates.apply_update(
                  parent_node |> trie_node.kind(),
                  None,
                )
              let child_key = parent_node.key

              remove_raw_while(
                trie,
                root_path_reversed,
                child_key,
                count_updates,
              )
            }
          }
        }
      }
    }
  }
}

// pub fn get_chunk_with_proof(
//   trie: MerkleRadixTrie(data),
//   keys_from: KeyNibbles,
//   limit: Int,
// ) -> TrieChunk {
//   todo
// }

// fn clear_stumps(
//   trie: MerkleRadixTrie(data),
//   keys_from: KeyNibbles,
// ) -> MerkleRadixTrie(data) {
//   todo
// }

// /// Marks empty stump children on the rightmost path in the tree.
// /// These stumps are stored in the existing nodes to mark the (yet) missing parts of the partial tree.
// /// We can know which children are missing by looking at the trie proof of this path.
// fn mark_stumps(
//   trie: MerkleRadixTrie(data),
//   keys_from: KeyNibbles,
//   last_item_proof: List(TrieProofNode),
// ) -> Result(MerkleRadixTrie(data), TrieError) {
//   todo
// }

// /// When pushing a chunk the correct behavior may result in an applied chunk or in an ignored chunk.
// /// `start_key` is inclusive and is meant to check if the chunk is a consecutive chunk.
// pub fn put_chunk(
//   trie: MerkleRadixTrie(data),
//   start_key: KeyNibbles,
//   chunk: TrieChunk,
//   expected_hash: BitArray,
// ) -> Result(#(MerkleRadixTrie(data), TrieChunkPushResult), TrieError) {
//   todo
// }

// /// `start_key` is inclusive and marks the first key to be removed.
// pub fn remove_chunk(
//   trie: MerkleRadixTrie(data),
//   start_key: KeyNibbles,
// ) -> Result(MerkleRadixTrie(data), TrieError) {
//   todo
// }

// pub fn get_proof(
//   trie: MerkleRadixTrie(data),
//   keys: List(KeyNibbles),
// ) -> Result(TrieProof, TrieError) {
//   todo
// }

pub fn update_root(trie: MerkleRadixTrie(data)) -> MerkleRadixTrie(data) {
  let #(trie, _root_hash) = trie |> update_hashes(key_nibbles.root())
  trie
}

// pub fn apply_diff(
//   trie: MerkleRadixTrie(data),
//   diff: TrieDiff,
// ) -> Result(#(MerkleRadixTrie(data), RevertTrieDiff), TrieError) {
//   todo
// }

// pub fn revert_diff(
//   trie: MerkleRadixTrie(data),
//   diff: RevertTrieDiff,
// ) -> Result(MerkleRadixTrie(data), TrieError) {
//   todo
// }

/// Returns the root node, if there is one.
fn get_root(trie: MerkleRadixTrie(data)) -> Option(TrieNode) {
  trie |> get_node(key_nibbles.root())
}

/// Updates the keys for a chain of nodes and marks those nodes as dirty. It assumes that the
/// path starts at the root node and that each consecutive node is a child of the previous node.
fn update_keys(
  trie: MerkleRadixTrie(data),
  root_path: List(TrieNode),
  count_updates: CountUpdates,
) -> MerkleRadixTrie(data) {
  let only_root_path_needs_update = root_path |> list.length() == 1
  let assert Ok(root) = root_path |> list.first()
    as "Root path must not be empty"

  let root_path = case count_updates |> count_updates.is_empty() {
    True -> root_path
    False -> {
      let assert Some(root_data) = root.root_data
        as "Root path must start with a root node"
      let root_data = count_updates |> count_updates.update_root_data(root_data)
      let root = TrieNode(..root, root_data: Some(root_data))
      // Replace root node at the first position of the path.
      [root, ..root_path |> list.drop(1)]
    }
  }

  case count_updates |> count_updates.is_empty(), only_root_path_needs_update {
    False, True -> {
      // "Early return"
      // TODO Investigate if I can use "use" for this in combination with the above count_updates update
      let assert Ok(root) = root_path |> list.first()
      trie |> put_node(root)
    }
    _, _ -> {
      let root_path_reversed = list.reverse(root_path)
      let assert Ok(child_node) = root_path_reversed |> list.first()
        as "Root path must not be empty!"
      let root_path_reversed = root_path_reversed |> list.drop(1)
      let #(trie, last_node) =
        root_path_reversed
        |> list.fold(#(trie, child_node), fn(acc, parent_node) {
          let #(trie, child_node) = acc
          let assert Ok(parent_node) =
            parent_node |> trie_node.put_child_no_hash(child_node.key)
          let trie = trie |> put_node(parent_node)
          #(trie, parent_node)
        })
      let assert True = last_node |> trie_node.is_root()
      trie
    }
  }
}

/// Updates the hashes of all dirty nodes in the subtree specified by `key`.
fn update_hashes(
  trie: MerkleRadixTrie(data),
  key: KeyNibbles,
) -> #(MerkleRadixTrie(data), BitArray) {
  let assert Some(node) = trie |> get_node(key)
  case node |> trie_node.has_children() {
    False -> {
      let hash = node |> trie_node.hash_assert()
      #(trie, hash)
    }
    True -> {
      let #(trie, children) =
        node.children
        |> iv.fold(#(trie, iv.new()), fn(acc, maybe_child) {
          let #(trie, children) = acc
          let #(trie, maybe_child) = case maybe_child {
            None -> #(trie, None)
            Some(child) -> {
              case child |> trie_node_child.has_hash() {
                True -> #(trie, Some(child))
                False -> {
                  let child_key = child |> trie_node_child.key(key)
                  // TODO: Try changing this recursion to benefit from tail call optimization.
                  let #(trie, hash) = trie |> update_hashes(child_key)
                  #(trie, Some(TrieNodeChild(..child, hash:)))
                }
              }
            }
          }
          #(trie, children |> iv.append(maybe_child))
        })
      let node = TrieNode(..node, children:)
      let trie = trie |> put_node(node)
      let hash = node |> trie_node.hash_assert()
      #(trie, hash)
    }
  }
}
// /// Returns the last key containing a value before the given key.
// fn get_predecessor(
//   trie: MerkleRadixTrie(data),
//   key: KeyNibbles,
// ) -> Option(KeyNibbles) {
//   todo
// }

// /// Returns the nodes of the chunk of the Merkle Radix Trie that starts at the key `start` and
// /// has size `size`. This is used by the `get_chunk` and `get_chunk_proof` functions.
// fn get_trie_chunk(
//   trie: MerkleRadixTrie(data),
//   start: KeyNibbles,
//   size: Int,
// ) -> List(TrieNode) {
//   todo
// }
