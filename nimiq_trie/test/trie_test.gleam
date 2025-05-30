import gleam/bit_array
import gleam/option.{None, Some}
import gleam/string
import gleam/yielder
import gleeunit/should

import account
import nimiq/trie
import nimiq/trie/backend
import nimiq/trie/key_nibbles

/// Adds one account to the trie and checks the root hash.
pub fn simple_trie_test() {
  let account = account.Basic(100_000)

  // NQ05 U1RF QJNH JCS1 RDQX 4M3Y 60KR K6CN 5LKC
  let assert Ok(key_1) =
    key_nibbles.from_str("e072fc4ad193341cb71e2547f30279999962d26c")

  let trie =
    trie.new(backend.memory(), account.serialize_to_vec, fn(bytes: BitArray) {
      let assert Ok(account) = account.deserialize_all(bytes)
      account
    })

  let trie = trie |> trie.put(key_1, account)

  let assert Some(hash) = trie |> trie.root_hash() as "complete trie"
  should.equal(
    hash |> bit_array.base16_encode() |> string.lowercase(),
    "8c83a162dbc67b9179a7bec49a6812bf475b74c4b6631236414d1b54c7e939a4",
  )

  should.equal(trie |> trie.num_branches(), 0)
  should.equal(trie |> trie.num_leaves(), 1)
  should.equal(trie |> trie.num_hybrids(), 0)
}

pub fn get_put_remove_test() {
  let assert Ok(key_1) = key_nibbles.from_str("413f22b3e")
  let assert Ok(key_2) = key_nibbles.from_str("413b39931")
  let assert Ok(key_3) = key_nibbles.from_str("413b397fa")
  let assert Ok(key_4) = key_nibbles.from_str("cfb986f5a")

  let trie =
    trie.new(backend.memory(), fn(num: Int) { <<num:32>> }, fn(bytes: BitArray) {
      case bytes {
        <<num:32>> -> num
        _ -> panic as "Deserialization failed"
      }
    })

  should.equal(trie |> trie.count_nodes(), #(0, 0, 0))

  let trie = trie |> trie.put(key_1, 80_085)
  should.equal(trie |> trie.count_nodes(), #(0, 0, 1))
  let trie = trie |> trie.put(key_2, 999)
  should.equal(trie |> trie.count_nodes(), #(1, 0, 2))
  let trie = trie |> trie.put(key_3, 1337)

  should.equal(trie |> trie.count_nodes(), #(2, 0, 3))
  should.equal(trie |> trie.get(key_1), Some(80_085))
  should.equal(trie |> trie.get(key_2), Some(999))
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), None)

  let trie = trie |> trie.remove(key_4)
  should.equal(trie |> trie.count_nodes(), #(2, 0, 3))
  should.equal(trie |> trie.get(key_1), Some(80_085))
  should.equal(trie |> trie.get(key_2), Some(999))
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), None)

  let trie = trie |> trie.remove(key_1)
  should.equal(trie |> trie.count_nodes(), #(1, 0, 2))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), Some(999))
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), None)

  let trie = trie |> trie.remove(key_2)
  should.equal(trie |> trie.count_nodes(), #(0, 0, 1))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), None)
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), None)

  let trie = trie |> trie.remove(key_3)
  should.equal(trie |> trie.count_nodes(), #(0, 0, 0))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), None)
  should.equal(trie |> trie.get(key_3), None)
  should.equal(trie |> trie.get(key_4), None)

  let trie = trie |> trie.remove(key_nibbles.root())
  should.equal(trie |> trie.count_nodes(), #(0, 0, 0))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), None)
  should.equal(trie |> trie.get(key_3), None)
  should.equal(trie |> trie.get(key_4), None)
}

pub fn hybrid_nodes_test() {
  let assert Ok(key_1) = key_nibbles.from_str("413f22")
  let assert Ok(key_2) = key_nibbles.from_str("413")
  let assert Ok(key_3) = key_nibbles.from_str("413f227fa")
  let assert Ok(key_4) = key_nibbles.from_str("413b391")
  let assert Ok(key_5) = key_nibbles.from_str("412324")

  let trie =
    trie.new(backend.memory(), fn(num: Int) { <<num:32>> }, fn(bytes: BitArray) {
      case bytes {
        <<num:32>> -> num
        _ -> panic as "Deserialization failed"
      }
    })

  let initial_hash = trie |> trie.root_hash_assert()
  should.equal(trie |> trie.count_nodes(), #(0, 0, 0))
  let trie = trie |> trie.put(key_1, 80_085)
  should.equal(trie |> trie.count_nodes(), #(0, 0, 1))
  let trie = trie |> trie.put(key_2, 999)
  should.equal(trie |> trie.count_nodes(), #(0, 1, 1))
  let trie = trie |> trie.put(key_3, 1337)
  should.equal(trie |> trie.count_nodes(), #(0, 2, 1))
  let trie = trie |> trie.put(key_4, 6969)

  should.equal(trie |> trie.count_nodes(), #(0, 2, 2))
  should.equal(trie |> trie.get(key_1), Some(80_085))
  should.equal(trie |> trie.get(key_2), Some(999))
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), Some(6969))
  should.equal(trie |> trie.get(key_5), None)

  let trie = trie |> trie.remove(key_5)
  should.equal(trie |> trie.count_nodes(), #(0, 2, 2))
  should.equal(trie |> trie.get(key_1), Some(80_085))
  should.equal(trie |> trie.get(key_2), Some(999))
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), Some(6969))
  should.equal(trie |> trie.get(key_5), None)

  let trie = trie |> trie.remove(key_1)
  should.equal(trie |> trie.count_nodes(), #(0, 1, 2))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), Some(999))
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), Some(6969))
  should.equal(trie |> trie.get(key_5), None)

  let trie = trie |> trie.remove(key_2)
  should.equal(trie |> trie.count_nodes(), #(1, 0, 2))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), None)
  should.equal(trie |> trie.get(key_3), Some(1337))
  should.equal(trie |> trie.get(key_4), Some(6969))
  should.equal(trie |> trie.get(key_5), None)

  let trie = trie |> trie.remove(key_3)
  should.equal(trie |> trie.count_nodes(), #(0, 0, 1))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), None)
  should.equal(trie |> trie.get(key_3), None)
  should.equal(trie |> trie.get(key_4), Some(6969))
  should.equal(trie |> trie.get(key_5), None)

  let trie = trie |> trie.remove(key_4)
  should.equal(trie |> trie.count_nodes(), #(0, 0, 0))
  should.equal(trie |> trie.get(key_1), None)
  should.equal(trie |> trie.get(key_2), None)
  should.equal(trie |> trie.get(key_3), None)
  should.equal(trie |> trie.get(key_4), None)
  should.equal(trie |> trie.get(key_5), None)

  should.equal(trie |> trie.root_hash_assert(), initial_hash)
}

pub fn can_handle_hybrid_node_with_one_child_test() {
  // Will produce the following tree:
  //
  //                 |
  //                413
  //                / \
  //          ..b391   ..f22
  //                     |
  //                   ..7fa

  let assert Ok(key_1) = key_nibbles.from_str("413f22")
  let assert Ok(key_2) = key_nibbles.from_str("413")
  let assert Ok(key_3) = key_nibbles.from_str("413f227fa")
  let assert Ok(key_4) = key_nibbles.from_str("413b391")

  let original =
    trie.new(backend.memory(), fn(num: Int) { <<num:32>> }, fn(bytes: BitArray) {
      case bytes {
        <<num:32>> -> num
        _ -> panic as "Deserialization failed"
      }
    })

  // Add the nodes and make sure put works correctly.
  let original = original |> trie.put(key_1, 80_085)
  should.equal(original |> trie.count_nodes(), #(0, 0, 1))
  let original = original |> trie.put(key_2, 999)
  should.equal(original |> trie.count_nodes(), #(0, 1, 1))
  let original = original |> trie.put(key_3, 1337)
  should.equal(original |> trie.count_nodes(), #(0, 2, 1))
  let original = original |> trie.put(key_4, 6969)
  let original = original |> trie.update_root()
  should.equal(original |> trie.count_nodes(), #(0, 2, 2))

  // Remove the nodes and make sure remove works correctly.
  let original = original |> trie.remove(key_4)
  should.equal(original |> trie.count_nodes(), #(0, 2, 1))
  let original = original |> trie.remove(key_3)
  should.equal(original |> trie.count_nodes(), #(0, 1, 1))
  let original = original |> trie.remove(key_2)
  should.equal(original |> trie.count_nodes(), #(0, 0, 1))
  let original = original |> trie.remove(key_1)
  should.equal(original |> trie.count_nodes(), #(0, 0, 0))
}

pub fn can_iterate_over_nodes_test() {
  let assert Ok(key_1) =
    key_nibbles.from_str("0000000000000000000000000000000000000000")
  let assert Ok(key_2) =
    key_nibbles.from_str("0000000000000000001000000000000000000000")
  let assert Ok(key_3) =
    key_nibbles.from_str("0000000000000000000000000000002000000000")
  let assert Ok(key_4) =
    key_nibbles.from_str("0000000300000000000000000000000000000000")

  let trie =
    trie.new(backend.memory(), fn(num: Int) { <<num:32>> }, fn(bytes: BitArray) {
      case bytes {
        <<num:32>> -> num
        _ -> panic as "Deserialization failed"
      }
    })

  let trie = trie |> trie.put(key_1, 1)
  let trie = trie |> trie.put(key_4, 4)
  let trie = trie |> trie.put(key_2, 2)
  let trie = trie |> trie.put(key_3, 3)

  let assert Ok(start_key) =
    key_nibbles.from_str("0000000000000000000000000000000000000000")
  let assert Ok(end_key) =
    key_nibbles.from_str("ffffffffffffffffffffffffffffffffffffffff")

  let iterator = trie |> trie.iter_nodes(start_key, end_key)

  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  should.equal(next, 1)
  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  should.equal(next, 3)
  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  should.equal(next, 2)
  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  should.equal(next, 4)
  let assert yielder.Done = iterator |> yielder.step()
}
