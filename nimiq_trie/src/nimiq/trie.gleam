import gleam/bool
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder}

import iv

import nimiq/trie/backend.{type Backend}
import nimiq/trie/count_updates.{type CountUpdates, CountUpdates}
import nimiq/trie/item.{type TrieItem}
import nimiq/trie/key_nibbles.{type KeyNibbles}
import nimiq/trie/node.{type TrieNode, TrieNode}
import nimiq/trie/node_child.{TrieNodeChild}

// import trie/chunk.{type TrieChunk, type TrieChunkPushResult}
// import trie/proof.{type TrieProof}
// import trie/proof_node.{type TrieProofNode}

pub type MerkleRadixTrie(data) {
  MerkleRadixTrie(
    table: Backend,
    serializer: fn(data) -> BitArray,
    deserializer: fn(BitArray) -> data,
  )
}

/// Start a new Merkle Radix Trie
pub fn new(
  table: Backend,
  serializer serializer: fn(data) -> BitArray,
  deserializer deserializer: fn(BitArray) -> data,
) -> MerkleRadixTrie(data) {
  let trie = MerkleRadixTrie(table:, deserializer:, serializer:)
  trie |> init_root()
  trie
}

fn init_root(trie: MerkleRadixTrie(data)) -> Nil {
  case trie |> get_root() {
    // Root already exists
    Some(_) -> Nil
    None -> {
      let root = node.new_root()
      trie |> put_node(root)
    }
  }
}

pub fn init(trie: MerkleRadixTrie(data), values: List(TrieItem)) -> Nil {
  // let assert True = trie |> is_complete()
  let assert 0 = trie |> num_leaves()
  let assert 0 = trie |> num_hybrids()

  values
  |> list.each(fn(pair) {
    let #(key, value) = pair
    trie |> put_raw(key, value)
  })

  trie |> update_root()

  Nil
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
      //   |> node.hash_assert()
      //   |> bit_array.base16_encode()
      //   |> string.lowercase()
      //   <> "]",
      // )
      node
      |> node.iter_children()
      |> iv.each(fn(child) {
        io.println(
          prefix
          <> "-> "
          <> child.suffix |> key_nibbles.to_string()
          <> " ("
          <> child |> node_child.has_hash() |> bool.to_string()
          <> ")",
        )
        let subkey = child |> node_child.key(key)
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
  root |> node.hash_assert()
}

/// Returns the root hash of the Merkle Radix Trie if the trie is complete.
pub fn root_hash(trie: MerkleRadixTrie(data)) -> Option(BitArray) {
  let assert Some(root) = trie |> get_root()
  root |> node.hash()
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
        |> node.iter_children()
        |> iv.fold(stack, fn(stack, child) {
          let child_key = child |> node_child.key(item.key)
          let assert Some(child) = trie |> get_node(child_key)
            as "Failed to find the child of a Merkle Radix Trie node. The database must be corrupt!"
          [child, ..stack]
        })
      case item |> node.kind() {
        None -> panic as "Empty nodes mustn't exist in the database"
        Some(node.Root) -> {
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
        Some(node.Branch) -> {
          let num_branches = num_branches + 1
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
        Some(node.Hybrid) -> {
          let num_hybrids = num_hybrids + 1
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
        Some(node.Leaf) -> {
          let num_leaves = num_leaves + 1
          count_nodes_while(trie, stack, num_branches, num_hybrids, num_leaves)
        }
      }
    }
  }
}

fn get_node(trie: MerkleRadixTrie(data), key: KeyNibbles) -> Option(TrieNode) {
  trie.table
  |> trie.table.get(key)
  |> result.replace_error(
    "Node not found for key " <> key |> key_nibbles.to_string(),
  )
  |> result.map(node.deserialize_all)
  |> result.flatten()
  |> result.map(fn(node) { TrieNode(..node, key: key) })
  |> option.from_result()
}

fn put_node(trie: MerkleRadixTrie(data), node: TrieNode) -> Nil {
  trie.table |> trie.table.set(node.key, node |> node.serialize_to_vec())
}

fn remove_node(trie: MerkleRadixTrie(data), key: KeyNibbles) -> Nil {
  trie.table |> trie.table.del(key)
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
) -> Nil {
  trie |> put_raw(key, value |> trie.serializer)
}

/// Insert a value into the Merkle Radix Trie at the given key. If the key already exists then
/// it will overwrite it. You can't use this function to check the existence of a given key.
fn put_raw(
  trie: MerkleRadixTrie(data),
  key: KeyNibbles,
  value: BitArray,
) -> Nil {
  // Start by getting the root node.
  let assert Some(cur_node) = trie |> get_root()
    as "Merkle Radix Trie must have a root node!"

  // And initialize the root path.
  let root_path: List(TrieNode) = list.new()

  let #(root_path, count_updates) =
    trie |> put_raw_loop(cur_node, root_path, key, value)

  trie |> update_keys(root_path, count_updates)
}

fn put_raw_loop(
  trie: MerkleRadixTrie(data),
  cur_node: TrieNode,
  root_path: List(TrieNode),
  key: KeyNibbles,
  value: BitArray,
) -> #(List(TrieNode), CountUpdates) {
  case cur_node.key |> key_nibbles.is_prefix_of(key) {
    // If the current node key is no longer a prefix for the given key then we need to
    // split the node.
    False -> {
      // Check if the new node is a sibling or the parent of cur_node.
      let #(root_path, count_updates) = case
        key |> key_nibbles.is_prefix_of(cur_node.key)
      {
        True -> {
          // The new node is the parent of the current node. Thus it needs to be a hybrid node.
          let assert Ok(new_node) =
            node.new_leaf(key, value)
            |> node.put_child_no_hash(cur_node.key)
          trie |> put_node(new_node)

          // Push the new node into the root path.
          let root_path = root_path |> list.append([new_node])
          let count_updates =
            CountUpdates(..count_updates.default(), hybrids: 1)
          #(root_path, count_updates)
        }
        False -> {
          // The new node is a sibling of the current node. Thus it is a leaf node.
          let new_node = node.new_leaf(key, value)
          trie |> put_node(new_node)

          // We insert a new branch node as the parent of both the current node and the
          // new node.
          let assert Ok(new_parent) =
            node.new_empty(cur_node.key |> key_nibbles.common_prefix(key))
            |> node.put_child_no_hash(cur_node.key)
            |> result.map(fn(new_parent) {
              new_parent
              |> node.put_child(new_node.key, new_node |> node.hash_assert())
            })
            |> result.flatten()
          trie |> put_node(new_parent)

          let count_updates =
            CountUpdates(..count_updates.default(), branches: 1, leaves: 1)
          // Push the parent node into the root path.
          let root_path = root_path |> list.append([new_parent])
          #(root_path, count_updates)
        }
      }
      // break
      #(root_path, count_updates)
    }
    True -> {
      // If the current node key is equal to the given key, we have found an existing node
      // with the given key. Update the value.
      case cur_node.key |> key_nibbles.equals(key) {
        True -> {
          // Update the node and store it.
          let prev_kind = cur_node |> node.kind()
          let assert Ok(#(cur_node, _old_value)) =
            cur_node |> node.put_value(value)
          trie |> put_node(cur_node)

          let count_updates =
            count_updates.from_update(prev_kind, cur_node |> node.kind())
          // Push the node into the root path.
          let root_path = root_path |> list.append([cur_node])
          // break
          #(root_path, count_updates)
        }
        False -> {
          // Try to find a child of the current node that matches our key.
          case cur_node |> node.child_key(key) {
            // If no matching child exists, add a new child to the current node.
            Error(_) -> {
              // Create and store the new node.
              let new_node = node.new_leaf(key, value)
              trie |> put_node(new_node)

              // Update the parent node and store it.
              let old_kind = cur_node |> node.kind()
              let assert Ok(cur_node) =
                cur_node
                |> node.put_child(new_node.key, new_node |> node.hash_assert())
              trie |> put_node(cur_node)

              let count_updates =
                CountUpdates(..count_updates.default(), leaves: 1)
                |> count_updates.apply_update(old_kind, cur_node |> node.kind())
              // Push the parent node into the root path.
              let root_path = root_path |> list.append([cur_node])
              // break
              #(root_path, count_updates)
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
pub fn remove(trie: MerkleRadixTrie(data), key: KeyNibbles) -> Nil {
  trie |> remove_raw(key)
}

/// Removes the value in the Merkle Radix Trie at the given key. If the key doesn't exist
/// then this function just returns silently. You can't use this to check the existence of a
/// given prefix.
fn remove_raw(trie: MerkleRadixTrie(data), key: KeyNibbles) -> Nil {
  // Start by getting the root node.
  let assert Some(cur_node) = trie |> get_root()
    as "Merkle Radix Trie must have a root node!"

  // And initialize the root path.
  let root_path: List(TrieNode) = list.new()

  // Go down the trie until you find the key.
  let #(root_path, should_continue) =
    trie |> remove_raw_loop(cur_node, root_path, key)

  case should_continue {
    False -> {
      // The loop `return`ed
      Nil
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
) -> #(List(TrieNode), Bool) {
  case cur_node.key |> key_nibbles.is_prefix_of(key) {
    False -> {
      // If the current node key is no longer a prefix for the given key then the key doesn't
      // exist and we stop here.
      // return
      #(root_path, False)
    }
    True -> {
      // If the current node key is equal to our given key, we have found our node.
      // Update/remove the node.
      case cur_node.key |> key_nibbles.equals(key) {
        True -> {
          // Remove the value from the node.
          let prev_kind = cur_node |> node.kind()
          let #(cur_node, _old_value) = cur_node |> node.take_value()

          case cur_node |> node.is_root() || cur_node |> node.has_children() {
            True -> {
              // Node was a hybrid node and is now a branch node.
              let num_children = cur_node |> node.iter_children() |> iv.size()

              // If it has only a single child and isn't the root node, merge it with that child.
              let #(root_path, count_updates) = case
                num_children == 1 && !{ cur_node |> node.is_root() }
              {
                True -> {
                  // Remove the node from the database.
                  trie |> remove_node(cur_node.key)

                  // Get the node's only child and add it to the root path.
                  let assert Ok(only_child_key) =
                    cur_node
                    |> node.iter_children()
                    |> iv.get(0)
                    |> result.map(fn(child) {
                      child |> node_child.key(cur_node.key)
                    })

                  let assert Some(only_child) = trie |> get_node(only_child_key)

                  let root_path = root_path |> list.append([only_child])

                  // We removed a hybrid node.
                  let count_updates =
                    CountUpdates(..count_updates.default(), hybrids: -1)

                  #(root_path, count_updates)
                }
                False -> {
                  // The node is root or has multiple children, thus we cannot remove it.
                  // Instead we converted it to a branch node by removing its value.

                  // We converted a hybrid node into a branch node.
                  // Or kept a branch node a branch node if there was no value stored before.
                  let count_updates =
                    count_updates.from_update(
                      prev_kind,
                      cur_node |> node.kind(),
                    )

                  // Update the node and add it to the root path.
                  trie |> put_node(cur_node)

                  let root_path = root_path |> list.append([cur_node])

                  #(root_path, count_updates)
                }
              }
              // Update the keys and hashes of the rest of the root path.
              trie |> update_keys(root_path, count_updates)
              // return
              #(root_path, False)
            }
            False -> {
              // Node was a leaf node, delete if from the database.
              trie |> remove_node(key)
              // break
              #(root_path, True)
            }
          }
        }
        False -> {
          // Try to find a child of the current node that matches our key.
          case cur_node |> node.child_key(key) {
            // If no matching child exists, then the key doesn't exist and we stop here.
            Error(_) -> {
              // return
              #(root_path, False)
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

fn remove_raw_while(
  trie: MerkleRadixTrie(data),
  root_path_reversed: List(TrieNode),
  child_key: KeyNibbles,
  count_updates: CountUpdates,
) -> Nil {
  case root_path_reversed {
    [] -> {
      Nil
    }
    [parent_node, ..root_path_reversed] -> {
      // Remove the child from the parent node.
      let prev_parent_kind = parent_node |> node.kind()
      let assert Ok(parent_node) = parent_node |> node.remove_child(child_key)
      let count_updates =
        count_updates
        |> count_updates.apply_update(
          prev_parent_kind,
          parent_node |> node.kind(),
        )

      // Get the number of children of the node.
      let num_children = parent_node |> node.iter_children() |> iv.size()

      // If the node has only a single child (and it isn't the root node), merge it with the
      // child.
      case
        num_children == 1
        && !{ parent_node |> node.is_root() }
        && !{ parent_node |> node.is_hybrid() }
      {
        True -> {
          // Remove the node from the database.
          trie |> remove_node(parent_node.key)
          let count_updates =
            count_updates
            |> count_updates.apply_update(parent_node |> node.kind(), None)

          // Get the node's only child and add it to the root path.
          let assert Ok(only_child_key) =
            parent_node
            |> node.iter_children()
            |> iv.get(0)
            |> result.map(fn(child) { child |> node_child.key(parent_node.key) })

          let assert Some(only_child) = trie |> get_node(only_child_key)

          let root_path_reversed = [only_child, ..root_path_reversed]

          // Update the keys and hashes of the rest of the root path.
          trie
          |> update_keys(root_path_reversed |> list.reverse(), count_updates)

          // return
          Nil
        }
        False -> {
          case parent_node |> node.is_empty() {
            // If the node has any children, or it is either the root or a hybrid node, we just store the
            // parent node in the database and the root path. Then we update the keys and hashes of
            // of the root path.
            False -> {
              trie |> put_node(parent_node)

              let root_path_reversed = [parent_node, ..root_path_reversed]

              // Update the keys and hashes of the rest of the root path.
              trie
              |> update_keys(
                root_path_reversed |> list.reverse(),
                count_updates,
              )

              // return
              Nil
            }
            // Otherwise, our node must have no children and not be the root/hybrid node. In this case we
            // need to remove it too, so we loop again.
            True -> {
              trie |> remove_node(parent_node.key)
              let count_updates =
                count_updates
                |> count_updates.apply_update(parent_node |> node.kind(), None)
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

pub fn update_root(trie: MerkleRadixTrie(data)) -> BitArray {
  trie |> update_hashes(key_nibbles.root())
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
) -> Nil {
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
      let last_node =
        root_path_reversed
        |> list.fold(child_node, fn(child_node, parent_node) {
          let assert Ok(parent_node) =
            parent_node |> node.put_child_no_hash(child_node.key)
          trie |> put_node(parent_node)
          parent_node
        })
      let assert True = last_node |> node.is_root()
      Nil
    }
  }
}

/// Updates the hashes of all dirty nodes in the subtree specified by `key`.
fn update_hashes(trie: MerkleRadixTrie(data), key: KeyNibbles) -> BitArray {
  let assert Some(node) = trie |> get_node(key)
  case node |> node.has_children() {
    False -> {
      node |> node.hash_assert()
    }
    True -> {
      let children =
        node.children
        |> iv.fold(iv.new(), fn(children, maybe_child) {
          let maybe_child = case maybe_child {
            None -> None
            Some(child) -> {
              case child |> node_child.has_hash() {
                True -> Some(child)
                False -> {
                  let child_key = child |> node_child.key(key)
                  // TODO: Try changing this recursion to benefit from tail call optimization.
                  let hash = trie |> update_hashes(child_key)
                  Some(TrieNodeChild(..child, hash:))
                }
              }
            }
          }
          children |> iv.append(maybe_child)
        })
      let node = TrieNode(..node, children:)
      trie |> put_node(node)
      node |> node.hash_assert()
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
// fn get_chunk(
//   trie: MerkleRadixTrie(data),
//   start: KeyNibbles,
//   size: Int,
// ) -> List(TrieNode) {
//   todo
// }

/// This iterator is meant to start at `start_key` and finish at `end_key`, both of these are inclusive.
pub fn iter_nodes(
  trie: MerkleRadixTrie(data),
  start_key start_key: KeyNibbles,
  end_key end_key: KeyNibbles,
) -> Yielder(data) {
  let assert True =
    start_key |> key_nibbles.len() == end_key |> key_nibbles.len()
    as "Start and end keys should have the same length"

  let keys =
    trie.table
    |> trie.table.keys(start_key, end_key)

  yielder.unfold(keys, fn(acc) {
    case acc {
      [] -> yielder.Done
      [key, ..rest] -> {
        let assert Some(node) = trie |> get_node(key)
        let assert Some(value) = node.value
        let value = value |> trie.deserializer()
        yielder.Next(value, rest)
      }
    }
  })
}

/// This iterator is meant to start at `start_key` and finish at `end_key`, both of these are inclusive.
pub fn iter_key_nodes(
  trie: MerkleRadixTrie(data),
  start_key start_key: KeyNibbles,
  end_key end_key: KeyNibbles,
) -> Yielder(#(KeyNibbles, data)) {
  let assert True =
    start_key |> key_nibbles.len() == end_key |> key_nibbles.len()
    as "Start and end keys should have the same length"

  let keys =
    trie.table
    |> trie.table.keys(start_key, end_key)

  yielder.unfold(keys, fn(acc) {
    case acc {
      [] -> yielder.Done
      [key, ..rest] -> {
        let assert Some(node) = trie |> get_node(key)
        let assert Some(value) = node.value
        let value = value |> trie.deserializer()
        yielder.Next(#(key, value), rest)
      }
    }
  })
}
