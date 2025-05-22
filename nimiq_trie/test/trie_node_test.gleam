import blake2b
import gleam/bit_array
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should
import key_nibbles
import trie/trie
import trie/trie_node.{TrieNode}
import utils

pub fn child_index_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  let branch_node = trie_node.new_empty(key)

  let child_key_1 = key_nibbles.from_str("cfb986f5a") |> utils.unwrap()
  let child_key_2 = key_nibbles.from_str("cfb986ab9") |> utils.unwrap()
  let child_key_3 = key_nibbles.from_str("cfb9860f6") |> utils.unwrap()
  let child_key_4 = key_nibbles.from_str("cfb986d50") |> utils.unwrap()

  should.equal(branch_node |> trie_node.child_index(child_key_1), Ok(15))
  should.equal(branch_node |> trie_node.child_index(child_key_2), Ok(10))
  should.equal(branch_node |> trie_node.child_index(child_key_3), Ok(0))
  should.equal(branch_node |> trie_node.child_index(child_key_4), Ok(13))

  should.equal(
    branch_node |> trie_node.child_index(child_key_1 |> key_nibbles.slice(0, 7)),
    Ok(15),
  )

  should.equal(leaf_node |> trie_node.child_index(child_key_2), Ok(10))

  let child_key_5 = key_nibbles.from_str("c0b986d50") |> utils.unwrap()
  should.equal(
    branch_node |> trie_node.child_index(child_key_5),
    Error(trie.WrongPrefix),
  )
}

pub fn child_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  let branch_node = trie_node.new_empty(key)

  let child_key_1 = key_nibbles.from_str("cfb986f5a") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_2 = key_nibbles.from_str("cfb986ab9") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_3 = key_nibbles.from_str("cfb9860f6") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_4 = key_nibbles.from_str("cfb986d50") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())
    |> utils.unwrap()

  should.equal(
    branch_node |> trie_node.child(child_key_1) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_1">> |> blake2b.hash()),
  )
  should.equal(
    branch_node |> trie_node.child(child_key_2) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_2">> |> blake2b.hash()),
  )
  should.equal(
    branch_node |> trie_node.child(child_key_3) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_3">> |> blake2b.hash()),
  )
  should.equal(
    branch_node |> trie_node.child(child_key_4) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_4">> |> blake2b.hash()),
  )

  should.equal(
    branch_node
      |> trie_node.child(child_key_1 |> key_nibbles.slice(0, 7))
      |> result.map(fn(c) { c.hash }),
    Ok(<<"child_1">> |> blake2b.hash()),
  )

  should.equal(
    leaf_node |> trie_node.child(child_key_2) |> result.map(fn(c) { c.hash }),
    Error(trie.ChildDoesNotExist),
  )

  let child_key_5 = key_nibbles.from_str("c0b986d50") |> utils.unwrap()
  should.equal(
    branch_node |> trie_node.child(child_key_5) |> result.map(fn(c) { c.hash }),
    Error(trie.WrongPrefix),
  )
}

pub fn child_key_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  let branch_node = trie_node.new_empty(key)

  let child_key_1 = key_nibbles.from_str("cfb986f5a") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_2 = key_nibbles.from_str("cfb986ab9") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_3 = key_nibbles.from_str("cfb9860f6") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_4 = key_nibbles.from_str("cfb986d50") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())
    |> utils.unwrap()

  should.be_true(
    branch_node
    |> trie_node.child_key(child_key_1)
    |> utils.unwrap()
    |> key_nibbles.equals(child_key_1),
  )
  should.be_true(
    branch_node
    |> trie_node.child_key(child_key_2)
    |> utils.unwrap()
    |> key_nibbles.equals(child_key_2),
  )
  should.be_true(
    branch_node
    |> trie_node.child_key(child_key_3)
    |> utils.unwrap()
    |> key_nibbles.equals(child_key_3),
  )
  should.be_true(
    branch_node
    |> trie_node.child_key(child_key_4)
    |> utils.unwrap()
    |> key_nibbles.equals(child_key_4),
  )
  should.be_true(
    branch_node
    |> trie_node.child_key(child_key_1 |> key_nibbles.slice(0, 7))
    |> utils.unwrap()
    |> key_nibbles.equals(child_key_1),
  )
  should.equal(
    leaf_node |> trie_node.child_key(child_key_2),
    Error(trie.ChildDoesNotExist),
  )

  let child_key_5 = key_nibbles.from_str("c0b986d50") |> utils.unwrap()
  should.equal(
    branch_node |> trie_node.child_key(child_key_5),
    Error(trie.WrongPrefix),
  )
}

pub fn put_remove_child_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let node = trie_node.new_leaf(key, <<66>>)

  let child_key_1 = key_nibbles.from_str("cfb986f5a") |> utils.unwrap()
  let node =
    node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_2 = key_nibbles.from_str("cfb986ab9") |> utils.unwrap()
  let node =
    node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_3 = key_nibbles.from_str("cfb9860f6") |> utils.unwrap()
  let node =
    node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_4 = key_nibbles.from_str("cfb986d50") |> utils.unwrap()
  let node =
    node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())
    |> utils.unwrap()

  let node = node |> trie_node.remove_child(child_key_1) |> utils.unwrap()
  should.equal(
    node |> trie_node.child(child_key_1),
    Error(trie.ChildDoesNotExist),
  )

  let node = node |> trie_node.remove_child(child_key_2) |> utils.unwrap()
  should.equal(
    node |> trie_node.child(child_key_2),
    Error(trie.ChildDoesNotExist),
  )

  let node = node |> trie_node.remove_child(child_key_3) |> utils.unwrap()
  should.equal(
    node |> trie_node.child(child_key_3),
    Error(trie.ChildDoesNotExist),
  )

  let node = node |> trie_node.remove_child(child_key_4) |> utils.unwrap()
  should.equal(
    node |> trie_node.child(child_key_4),
    Error(trie.ChildDoesNotExist),
  )

  should.equal(node.value, Some(<<66>>))
}

pub fn put_value_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  should.equal(leaf_node.value, Some(<<66>>))
  let leaf_node = leaf_node |> trie_node.put_value(<<99>>) |> utils.unwrap()
  should.equal(leaf_node.value, Some(<<99>>))

  let hybrid_node = trie_node.new_leaf(key, <<66>>)
  should.equal(hybrid_node.value, Some(<<66>>))
  let hybrid_node = hybrid_node |> trie_node.put_value(<<99>>) |> utils.unwrap()
  should.equal(hybrid_node.value, Some(<<99>>))

  let branch_node = trie_node.new_empty(key)
  should.equal(branch_node.value, None)
  let branch_node = branch_node |> trie_node.put_value(<<99>>) |> utils.unwrap()
  should.equal(branch_node.value, Some(<<99>>))

  let root_node = trie_node.new_root()
  should.equal(root_node.value, None)
  should.equal(
    root_node |> trie_node.put_value(<<99>>),
    Error(trie.RootCantHaveValue),
  )
  should.equal(root_node.value, None)
}

pub fn remove_value_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  should.equal(leaf_node.value, Some(<<66>>))
  let leaf_node = TrieNode(..leaf_node, value: None)
  should.be_true(leaf_node |> trie_node.is_empty())

  let branch_node = trie_node.new_empty(key)
  should.equal(branch_node.value, None)

  let root_node = trie_node.new_root()
  should.equal(root_node.value, None)
}

pub fn hash_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let branch_node = trie_node.new_empty(key)

  let child_key_1 = key_nibbles.from_str("cfb986f5a") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_2 = key_nibbles.from_str("cfb986ab9") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_3 = key_nibbles.from_str("cfb9860f6") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_4 = key_nibbles.from_str("cfb986d50") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())
    |> utils.unwrap()

  should.equal(
    branch_node
      |> trie_node.hash()
      |> option.map(fn(h) {
        h |> bit_array.base16_encode() |> string.lowercase()
      }),
    // This hash was generated in rs-reference
    Some("d94a2c15ad309f8ca8802da6ca4f482f9d40ca9fd2646c12b783acba70a2807c"),
  )
}

pub fn serialize_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let branch_node = trie_node.new_empty(key)

  let child_key_1 = key_nibbles.from_str("cfb986f5a") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_2 = key_nibbles.from_str("cfb986ab9") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_3 = key_nibbles.from_str("cfb9860f6") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())
    |> utils.unwrap()

  let child_key_4 = key_nibbles.from_str("cfb986d50") |> utils.unwrap()
  let branch_node =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())
    |> utils.unwrap()

  should.equal(
    branch_node
      |> trie_node.serialize_to_vec()
      |> bit_array.base16_encode()
      |> string.lowercase(),
    // This serialization was generated in rs-reference
    "000000040103020f60b829fac4b0785910826b0ddea3612127f4d6311134c803c0d020c29c18770f26000000000000000000010302ab90f659ba1ff75e7e0f325d3974c33a332a7637b71e753b3e6dee9219799de3d6630000010302d5006b83553e1f4cc008f5649b1fed18e574298801c87957b56d7ea1d10f484b38aa00010302f5a0044ce2ce3d668da26636a44865e33341be59835b5490c1764a0dd3bcb33a96b1",
  )
}

pub fn deserialize_test() {
  let key = key_nibbles.from_str("cfb986") |> utils.unwrap()

  let branch_node =
    trie_node.deserialize_all(
      bit_array.base16_decode(
        "000000040103020f60b829fac4b0785910826b0ddea3612127f4d6311134c803c0d020c29c18770f26000000000000000000010302ab90f659ba1ff75e7e0f325d3974c33a332a7637b71e753b3e6dee9219799de3d6630000010302d5006b83553e1f4cc008f5649b1fed18e574298801c87957b56d7ea1d10f484b38aa00010302f5a0044ce2ce3d668da26636a44865e33341be59835b5490c1764a0dd3bcb33a96b1",
      )
      |> utils.unwrap(),
    )
    |> utils.unwrap()

  // Set correct key (the key is not part of the serialization)
  let branch_node = TrieNode(..branch_node, key:)

  should.be_none(branch_node.root_data)
  should.be_none(branch_node.value)

  let child_key_1 = key_nibbles.from_str("cfb986f5a") |> utils.unwrap()
  let child_key_2 = key_nibbles.from_str("cfb986ab9") |> utils.unwrap()
  let child_key_3 = key_nibbles.from_str("cfb9860f6") |> utils.unwrap()
  let child_key_4 = key_nibbles.from_str("cfb986d50") |> utils.unwrap()

  should.equal(
    branch_node |> trie_node.child(child_key_1) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_1">> |> blake2b.hash()),
  )
  should.equal(
    branch_node |> trie_node.child(child_key_2) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_2">> |> blake2b.hash()),
  )
  should.equal(
    branch_node |> trie_node.child(child_key_3) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_3">> |> blake2b.hash()),
  )
  should.equal(
    branch_node |> trie_node.child(child_key_4) |> result.map(fn(c) { c.hash }),
    Ok(<<"child_4">> |> blake2b.hash()),
  )

  should.equal(
    branch_node
      |> trie_node.child(child_key_1 |> key_nibbles.slice(0, 7))
      |> result.map(fn(c) { c.hash }),
    Ok(<<"child_1">> |> blake2b.hash()),
  )

  let child_key_5 = key_nibbles.from_str("c0b986d50") |> utils.unwrap()
  should.equal(
    branch_node |> trie_node.child(child_key_5) |> result.map(fn(c) { c.hash }),
    Error(trie.WrongPrefix),
  )
}
