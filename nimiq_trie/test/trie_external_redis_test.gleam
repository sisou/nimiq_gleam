import gleam/bit_array
import gleam/option.{None, Some}
import gleam/string
import gleam/yielder

import radish

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

  let assert Ok(read_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])
  let assert Ok(write_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])

  let trie =
    trie.new(
      backend.external_redis(
        read_client:,
        write_client:,
        timeout: 1000,
        key_prefix: "external_redis_test:",
      ),
      account.serialize_to_vec,
      fn(bytes: BitArray) {
        let assert Ok(account) = account.deserialize_all(bytes)
        account
      },
    )

  trie |> trie.put(key_1, account)

  let assert Some(hash) = trie |> trie.root_hash() as "complete trie"
  assert hash |> bit_array.base16_encode() |> string.lowercase()
    == "8c83a162dbc67b9179a7bec49a6812bf475b74c4b6631236414d1b54c7e939a4"

  assert trie |> trie.num_branches() == 0
  assert trie |> trie.num_leaves() == 1
  assert trie |> trie.num_hybrids() == 0

  cleanup(trie)
}

pub fn get_put_remove_test() {
  let assert Ok(key_1) = key_nibbles.from_str("413f22b3e")
  let assert Ok(key_2) = key_nibbles.from_str("413b39931")
  let assert Ok(key_3) = key_nibbles.from_str("413b397fa")
  let assert Ok(key_4) = key_nibbles.from_str("cfb986f5a")

  let assert Ok(read_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])
  let assert Ok(write_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])

  let trie =
    trie.new(
      backend.external_redis(
        read_client:,
        write_client:,
        timeout: 1000,
        key_prefix: "external_redis_test:",
      ),
      fn(num: Int) { <<num:32>> },
      fn(bytes: BitArray) {
        case bytes {
          <<num:32>> -> num
          _ -> panic as "Deserialization failed"
        }
      },
    )

  assert trie |> trie.count_nodes() == #(0, 0, 0)

  trie |> trie.put(key_1, 80_085)
  assert trie |> trie.count_nodes() == #(0, 0, 1)
  trie |> trie.put(key_2, 999)
  assert trie |> trie.count_nodes() == #(1, 0, 2)
  trie |> trie.put(key_3, 1337)

  assert trie |> trie.count_nodes() == #(2, 0, 3)
  assert trie |> trie.get(key_1) == Some(80_085)
  assert trie |> trie.get(key_2) == Some(999)
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == None

  trie |> trie.remove(key_4)
  assert trie |> trie.count_nodes() == #(2, 0, 3)
  assert trie |> trie.get(key_1) == Some(80_085)
  assert trie |> trie.get(key_2) == Some(999)
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == None

  trie |> trie.remove(key_1)
  assert trie |> trie.count_nodes() == #(1, 0, 2)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == Some(999)
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == None

  trie |> trie.remove(key_2)
  assert trie |> trie.count_nodes() == #(0, 0, 1)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == None
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == None

  trie |> trie.remove(key_3)
  assert trie |> trie.count_nodes() == #(0, 0, 0)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == None
  assert trie |> trie.get(key_3) == None
  assert trie |> trie.get(key_4) == None

  trie |> trie.remove(key_nibbles.root())
  assert trie |> trie.count_nodes() == #(0, 0, 0)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == None
  assert trie |> trie.get(key_3) == None
  assert trie |> trie.get(key_4) == None

  cleanup(trie)
}

pub fn hybrid_nodes_test() {
  let assert Ok(key_1) = key_nibbles.from_str("413f22")
  let assert Ok(key_2) = key_nibbles.from_str("413")
  let assert Ok(key_3) = key_nibbles.from_str("413f227fa")
  let assert Ok(key_4) = key_nibbles.from_str("413b391")
  let assert Ok(key_5) = key_nibbles.from_str("412324")

  let assert Ok(read_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])
  let assert Ok(write_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])

  let trie =
    trie.new(
      backend.external_redis(
        read_client:,
        write_client:,
        timeout: 1000,
        key_prefix: "external_redis_test:",
      ),
      fn(num: Int) { <<num:32>> },
      fn(bytes: BitArray) {
        case bytes {
          <<num:32>> -> num
          _ -> panic as "Deserialization failed"
        }
      },
    )

  let initial_hash = trie |> trie.root_hash_assert()
  assert trie |> trie.count_nodes() == #(0, 0, 0)
  trie |> trie.put(key_1, 80_085)
  assert trie |> trie.count_nodes() == #(0, 0, 1)
  trie |> trie.put(key_2, 999)
  assert trie |> trie.count_nodes() == #(0, 1, 1)
  trie |> trie.put(key_3, 1337)
  assert trie |> trie.count_nodes() == #(0, 2, 1)
  trie |> trie.put(key_4, 6969)

  assert trie |> trie.count_nodes() == #(0, 2, 2)
  assert trie |> trie.get(key_1) == Some(80_085)
  assert trie |> trie.get(key_2) == Some(999)
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == Some(6969)
  assert trie |> trie.get(key_5) == None

  trie |> trie.remove(key_5)
  assert trie |> trie.count_nodes() == #(0, 2, 2)
  assert trie |> trie.get(key_1) == Some(80_085)
  assert trie |> trie.get(key_2) == Some(999)
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == Some(6969)
  assert trie |> trie.get(key_5) == None

  trie |> trie.remove(key_1)
  assert trie |> trie.count_nodes() == #(0, 1, 2)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == Some(999)
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == Some(6969)
  assert trie |> trie.get(key_5) == None

  trie |> trie.remove(key_2)
  assert trie |> trie.count_nodes() == #(1, 0, 2)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == None
  assert trie |> trie.get(key_3) == Some(1337)
  assert trie |> trie.get(key_4) == Some(6969)
  assert trie |> trie.get(key_5) == None

  trie |> trie.remove(key_3)
  assert trie |> trie.count_nodes() == #(0, 0, 1)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == None
  assert trie |> trie.get(key_3) == None
  assert trie |> trie.get(key_4) == Some(6969)
  assert trie |> trie.get(key_5) == None

  trie |> trie.remove(key_4)
  assert trie |> trie.count_nodes() == #(0, 0, 0)
  assert trie |> trie.get(key_1) == None
  assert trie |> trie.get(key_2) == None
  assert trie |> trie.get(key_3) == None
  assert trie |> trie.get(key_4) == None
  assert trie |> trie.get(key_5) == None

  assert trie |> trie.root_hash_assert() == initial_hash

  cleanup(trie)
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

  let assert Ok(read_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])
  let assert Ok(write_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])

  let original =
    trie.new(
      backend.external_redis(
        read_client:,
        write_client:,
        timeout: 1000,
        key_prefix: "external_redis_test:",
      ),
      fn(num: Int) { <<num:32>> },
      fn(bytes: BitArray) {
        case bytes {
          <<num:32>> -> num
          _ -> panic as "Deserialization failed"
        }
      },
    )

  // Add the nodes and make sure put works correctly.
  original |> trie.put(key_1, 80_085)
  assert original |> trie.count_nodes() == #(0, 0, 1)
  original |> trie.put(key_2, 999)
  assert original |> trie.count_nodes() == #(0, 1, 1)
  original |> trie.put(key_3, 1337)
  assert original |> trie.count_nodes() == #(0, 2, 1)
  original |> trie.put(key_4, 6969)
  original |> trie.update_root()
  assert original |> trie.count_nodes() == #(0, 2, 2)

  // Remove the nodes and make sure remove works correctly.
  original |> trie.remove(key_4)
  assert original |> trie.count_nodes() == #(0, 2, 1)
  original |> trie.remove(key_3)
  assert original |> trie.count_nodes() == #(0, 1, 1)
  original |> trie.remove(key_2)
  assert original |> trie.count_nodes() == #(0, 0, 1)
  original |> trie.remove(key_1)
  assert original |> trie.count_nodes() == #(0, 0, 0)

  original |> cleanup()
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

  let assert Ok(read_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])
  let assert Ok(write_client) =
    radish.start("localhost", 6379, [radish.PoolSize(1)])

  let trie =
    trie.new(
      backend.external_redis(
        read_client:,
        write_client:,
        timeout: 1000,
        key_prefix: "external_redis_test:",
      ),
      fn(num: Int) { <<num:32>> },
      fn(bytes: BitArray) {
        case bytes {
          <<num:32>> -> num
          _ -> panic as "Deserialization failed"
        }
      },
    )

  trie |> trie.put(key_1, 1)
  trie |> trie.put(key_4, 4)
  trie |> trie.put(key_2, 2)
  trie |> trie.put(key_3, 3)

  let assert Ok(start_key) =
    key_nibbles.from_str("0000000000000000000000000000000000000000")
  let assert Ok(end_key) =
    key_nibbles.from_str("ffffffffffffffffffffffffffffffffffffffff")

  let iterator = trie |> trie.iter_nodes(start_key, end_key)

  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  assert next == 1
  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  assert next == 3
  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  assert next == 2
  let assert yielder.Next(next, iterator) = iterator |> yielder.step()
  assert next == 4
  let assert yielder.Done = iterator |> yielder.step()

  cleanup(trie)
}

fn cleanup(trie: trie.MerkleRadixTrie(data)) {
  let assert backend.ExternalRedis(write_client:, ..) = trie.table.store
  write_client |> radish.execute(["FLUSHDB"], 1000)
}
