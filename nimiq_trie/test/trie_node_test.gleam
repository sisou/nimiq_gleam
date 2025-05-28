import gleam/bit_array
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should

import blake2b
import key_nibbles
import trie/trie_error
import trie/trie_node.{TrieNode}

pub fn child_index_test() {
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  let branch_node = trie_node.new_empty(key)

  let assert Ok(child_key_1) = key_nibbles.from_str("cfb986f5a")
  let assert Ok(child_key_2) = key_nibbles.from_str("cfb986ab9")
  let assert Ok(child_key_3) = key_nibbles.from_str("cfb9860f6")
  let assert Ok(child_key_4) = key_nibbles.from_str("cfb986d50")

  should.equal(branch_node |> trie_node.child_index(child_key_1), Ok(15))
  should.equal(branch_node |> trie_node.child_index(child_key_2), Ok(10))
  should.equal(branch_node |> trie_node.child_index(child_key_3), Ok(0))
  should.equal(branch_node |> trie_node.child_index(child_key_4), Ok(13))

  should.equal(
    branch_node |> trie_node.child_index(child_key_1 |> key_nibbles.slice(0, 7)),
    Ok(15),
  )

  should.equal(leaf_node |> trie_node.child_index(child_key_2), Ok(10))

  let assert Ok(child_key_5) = key_nibbles.from_str("c0b986d50")
  should.equal(
    branch_node |> trie_node.child_index(child_key_5),
    Error(trie_error.WrongPrefix),
  )
}

pub fn child_test() {
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  let branch_node = trie_node.new_empty(key)

  let assert Ok(child_key_1) = key_nibbles.from_str("cfb986f5a")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())

  let assert Ok(child_key_2) = key_nibbles.from_str("cfb986ab9")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())

  let assert Ok(child_key_3) = key_nibbles.from_str("cfb9860f6")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())

  let assert Ok(child_key_4) = key_nibbles.from_str("cfb986d50")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())

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
    Error(trie_error.ChildDoesNotExist),
  )

  let assert Ok(child_key_5) = key_nibbles.from_str("c0b986d50")
  should.equal(
    branch_node |> trie_node.child(child_key_5) |> result.map(fn(c) { c.hash }),
    Error(trie_error.WrongPrefix),
  )
}

pub fn child_key_test() {
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  let branch_node = trie_node.new_empty(key)

  let assert Ok(child_key_1) = key_nibbles.from_str("cfb986f5a")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())

  let assert Ok(child_key_2) = key_nibbles.from_str("cfb986ab9")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())

  let assert Ok(child_key_3) = key_nibbles.from_str("cfb9860f6")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())

  let assert Ok(child_key_4) = key_nibbles.from_str("cfb986d50")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())

  should.equal(
    branch_node
      |> trie_node.child_key(child_key_1)
      |> result.map(fn(key) { key |> key_nibbles.equals(child_key_1) }),
    Ok(True),
  )
  should.equal(
    branch_node
      |> trie_node.child_key(child_key_2)
      |> result.map(fn(key) { key |> key_nibbles.equals(child_key_2) }),
    Ok(True),
  )
  should.equal(
    branch_node
      |> trie_node.child_key(child_key_3)
      |> result.map(fn(key) { key |> key_nibbles.equals(child_key_3) }),
    Ok(True),
  )
  should.equal(
    branch_node
      |> trie_node.child_key(child_key_4)
      |> result.map(fn(key) { key |> key_nibbles.equals(child_key_4) }),
    Ok(True),
  )
  should.equal(
    branch_node
      |> trie_node.child_key(child_key_1 |> key_nibbles.slice(0, 7))
      |> result.map(fn(key) { key |> key_nibbles.equals(child_key_1) }),
    Ok(True),
  )
  should.equal(
    leaf_node |> trie_node.child_key(child_key_2),
    Error(trie_error.ChildDoesNotExist),
  )

  let assert Ok(child_key_5) = key_nibbles.from_str("c0b986d50")
  should.equal(
    branch_node |> trie_node.child_key(child_key_5),
    Error(trie_error.WrongPrefix),
  )
}

pub fn put_remove_child_test() {
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let node = trie_node.new_leaf(key, <<66>>)

  let assert Ok(child_key_1) = key_nibbles.from_str("cfb986f5a")
  let assert Ok(node) =
    node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())

  let assert Ok(child_key_2) = key_nibbles.from_str("cfb986ab9")
  let assert Ok(node) =
    node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())

  let assert Ok(child_key_3) = key_nibbles.from_str("cfb9860f6")
  let assert Ok(node) =
    node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())

  let assert Ok(child_key_4) = key_nibbles.from_str("cfb986d50")
  let assert Ok(node) =
    node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())

  let assert Ok(node) = node |> trie_node.remove_child(child_key_1)
  should.equal(
    node |> trie_node.child(child_key_1),
    Error(trie_error.ChildDoesNotExist),
  )

  let assert Ok(node) = node |> trie_node.remove_child(child_key_2)
  should.equal(
    node |> trie_node.child(child_key_2),
    Error(trie_error.ChildDoesNotExist),
  )

  let assert Ok(node) = node |> trie_node.remove_child(child_key_3)
  should.equal(
    node |> trie_node.child(child_key_3),
    Error(trie_error.ChildDoesNotExist),
  )

  let assert Ok(node) = node |> trie_node.remove_child(child_key_4)
  should.equal(
    node |> trie_node.child(child_key_4),
    Error(trie_error.ChildDoesNotExist),
  )

  should.equal(node.value, Some(<<66>>))
}

pub fn put_value_test() {
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let leaf_node = trie_node.new_leaf(key, <<66>>)
  should.equal(leaf_node.value, Some(<<66>>))
  let assert Ok(#(leaf_node, _prev_value)) =
    leaf_node |> trie_node.put_value(<<99>>)
  should.equal(leaf_node.value, Some(<<99>>))

  let hybrid_node = trie_node.new_leaf(key, <<66>>)
  should.equal(hybrid_node.value, Some(<<66>>))
  let assert Ok(#(hybrid_node, _prev_value)) =
    hybrid_node |> trie_node.put_value(<<99>>)
  should.equal(hybrid_node.value, Some(<<99>>))

  let branch_node = trie_node.new_empty(key)
  should.equal(branch_node.value, None)
  let assert Ok(#(branch_node, _prev_value)) =
    branch_node |> trie_node.put_value(<<99>>)
  should.equal(branch_node.value, Some(<<99>>))

  let root_node = trie_node.new_root()
  should.equal(root_node.value, None)
  should.equal(
    root_node |> trie_node.put_value(<<99>>),
    Error(trie_error.RootCantHaveValue),
  )
  should.equal(root_node.value, None)
}

pub fn remove_value_test() {
  let assert Ok(key) = key_nibbles.from_str("cfb986")

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
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let branch_node = trie_node.new_empty(key)

  let assert Ok(child_key_1) = key_nibbles.from_str("cfb986f5a")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())

  let assert Ok(child_key_2) = key_nibbles.from_str("cfb986ab9")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())

  let assert Ok(child_key_3) = key_nibbles.from_str("cfb9860f6")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())

  let assert Ok(child_key_4) = key_nibbles.from_str("cfb986d50")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())

  should.equal(
    branch_node
      |> trie_node.hash_assert()
      |> bit_array.base16_encode()
      |> string.lowercase(),
    // This hash was generated in rs-reference
    "d94a2c15ad309f8ca8802da6ca4f482f9d40ca9fd2646c12b783acba70a2807c",
  )

  let assert Ok(key) =
    key_nibbles.from_str("e072fc4ad193341cb71e2547f30279999962d26c")
  let assert Ok(value) = bit_array.base16_decode("0000000000000186a0")
  let leaf_node = trie_node.new_leaf(key, value)

  should.equal(
    leaf_node
      |> trie_node.hash_assert()
      |> bit_array.base16_encode()
      |> string.lowercase(),
    // This hash was generated in rs-reference
    "ff95a8e7a35983fea7b44610136f00a20d4d00af0e46dd49748a35f6d5dad634",
  )
}

pub fn serialize_test() {
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let branch_node = trie_node.new_empty(key)

  let assert Ok(child_key_1) = key_nibbles.from_str("cfb986f5a")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_1, <<"child_1">> |> blake2b.hash())

  let assert Ok(child_key_2) = key_nibbles.from_str("cfb986ab9")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_2, <<"child_2">> |> blake2b.hash())

  let assert Ok(child_key_3) = key_nibbles.from_str("cfb9860f6")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_3, <<"child_3">> |> blake2b.hash())

  let assert Ok(child_key_4) = key_nibbles.from_str("cfb986d50")
  let assert Ok(branch_node) =
    branch_node
    |> trie_node.put_child(child_key_4, <<"child_4">> |> blake2b.hash())

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
  let assert Ok(key) = key_nibbles.from_str("cfb986")

  let assert Ok(Ok(branch_node)) =
    bit_array.base16_decode(
      "000000040103020f60b829fac4b0785910826b0ddea3612127f4d6311134c803c0d020c29c18770f26000000000000000000010302ab90f659ba1ff75e7e0f325d3974c33a332a7637b71e753b3e6dee9219799de3d6630000010302d5006b83553e1f4cc008f5649b1fed18e574298801c87957b56d7ea1d10f484b38aa00010302f5a0044ce2ce3d668da26636a44865e33341be59835b5490c1764a0dd3bcb33a96b1",
    )
    |> result.map(fn(bytes) { bytes |> trie_node.deserialize_all() })

  // Set correct key (the key is not part of the serialization)
  let branch_node = TrieNode(..branch_node, key:)

  should.be_none(branch_node.root_data)
  should.be_none(branch_node.value)

  let assert Ok(child_key_1) = key_nibbles.from_str("cfb986f5a")
  let assert Ok(child_key_2) = key_nibbles.from_str("cfb986ab9")
  let assert Ok(child_key_3) = key_nibbles.from_str("cfb9860f6")
  let assert Ok(child_key_4) = key_nibbles.from_str("cfb986d50")

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

  let assert Ok(child_key_5) = key_nibbles.from_str("c0b986d50")
  should.equal(
    branch_node |> trie_node.child(child_key_5) |> result.map(fn(c) { c.hash }),
    Error(trie_error.WrongPrefix),
  )
}
