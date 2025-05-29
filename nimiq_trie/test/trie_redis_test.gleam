import gleam/bit_array
import gleam/option.{Some}
import gleam/string
import gleeunit/should

import radish

import account
import backend
import key_nibbles
import trie/trie

/// Adds one account to the trie and checks the root hash.
pub fn simple_trie_redis_test() {
  let account = account.Basic(100_000)

  // NQ05 U1RF QJNH JCS1 RDQX 4M3Y 60KR K6CN 5LKC
  let assert Ok(key_1) =
    key_nibbles.from_str("e072fc4ad193341cb71e2547f30279999962d26c")

  let trie =
    trie.new(
      backend.redis("localhost", 6379, [radish.PoolSize(1)]),
      account.serialize_to_vec,
      fn(bytes: BitArray) {
        let assert Ok(account) = account.deserialize_all(bytes)
        account
      },
    )

  let trie = trie |> trie.put(key_1, account)

  let assert Some(hash) = trie |> trie.root_hash() as "complete trie"
  should.equal(
    hash |> bit_array.base16_encode() |> string.lowercase(),
    "8c83a162dbc67b9179a7bec49a6812bf475b74c4b6631236414d1b54c7e939a4",
  )

  should.equal(trie |> trie.num_branches(), 0)
  should.equal(trie |> trie.num_leaves(), 1)
  should.equal(trie |> trie.num_hybrids(), 0)

  // Cleanup
  trie |> trie.remove(key_1)
}
