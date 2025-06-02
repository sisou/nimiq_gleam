import gleam/option.{None, Some}

import nimiq/trie/key_nibbles

pub fn to_from_str_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")
  assert key |> key_nibbles.to_string()
    == "cfb98637bcae43c13323eaa1731ced2b716962fd"
  let assert Ok(key) = key_nibbles.from_str("")
  assert key |> key_nibbles.to_string() == "ROOT"

  let assert Ok(key) = key_nibbles.from_str("ROOT")
  assert key |> key_nibbles.to_string() == "ROOT"

  let assert Ok(key) = key_nibbles.from_str("1")
  assert key |> key_nibbles.to_string() == "1"

  let assert Ok(key) = key_nibbles.from_str("23")
  assert key |> key_nibbles.to_string() == "23"
}

pub fn sum_test() {
  let assert Ok(key1) = key_nibbles.from_str("cfb")
  let assert Ok(key2) = key_nibbles.from_str("986")

  assert key1 |> key_nibbles.add(key2) |> key_nibbles.to_string() == "cfb986"

  let assert Ok(key1) = key_nibbles.from_str("cfb9")
  let assert Ok(key2) = key_nibbles.from_str("8637")

  assert key1 |> key_nibbles.add(key2) |> key_nibbles.to_string() == "cfb98637"
}

pub fn get_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")

  assert key |> key_nibbles.get(0) == Some(12)
  assert key |> key_nibbles.get(1) == Some(15)
  assert key |> key_nibbles.get(2) == Some(11)
  assert key |> key_nibbles.get(3) == Some(9)
  assert key |> key_nibbles.get(41) == None
  assert key |> key_nibbles.get(42) == None
}

pub fn nibbles_slice_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")

  assert key |> key_nibbles.slice(0, 1) |> key_nibbles.to_string() == "c"
  assert key |> key_nibbles.slice(0, 2) |> key_nibbles.to_string() == "cf"
  assert key |> key_nibbles.slice(0, 3) |> key_nibbles.to_string() == "cfb"
  assert key |> key_nibbles.slice(1, 3) |> key_nibbles.to_string() == "fb"
  assert key |> key_nibbles.slice(0, 41) |> key_nibbles.to_string()
    == "cfb98637bcae43c13323eaa1731ced2b716962fd"
  assert key |> key_nibbles.slice(1, 40) |> key_nibbles.to_string()
    == "fb98637bcae43c13323eaa1731ced2b716962fd"
  assert key |> key_nibbles.slice(2, 1) |> key_nibbles.to_string() == "ROOT"
  assert key |> key_nibbles.slice(42, 43) |> key_nibbles.to_string() == "ROOT"
}

pub fn nibbles_suffix_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")

  assert key |> key_nibbles.suffix(0) |> key_nibbles.to_string()
    == "cfb98637bcae43c13323eaa1731ced2b716962fd"

  assert key |> key_nibbles.suffix(1) |> key_nibbles.to_string()
    == "fb98637bcae43c13323eaa1731ced2b716962fd"

  assert key |> key_nibbles.suffix(2) |> key_nibbles.to_string()
    == "b98637bcae43c13323eaa1731ced2b716962fd"

  assert key |> key_nibbles.suffix(40) |> key_nibbles.to_string() == "ROOT"
  assert key |> key_nibbles.suffix(42) |> key_nibbles.to_string() == "ROOT"
}

pub fn nibbles_is_prefix_of_test() {
  let assert Ok(key1) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")
  let assert Ok(key2) = key_nibbles.from_str("cfb")

  assert key2 |> key_nibbles.is_prefix_of(key1) == True
  assert key1 |> key_nibbles.is_prefix_of(key2) == False
}

pub fn nibbles_common_prefix_test() {
  let assert Ok(key1) =
    key_nibbles.from_str("1000000000000000000000000000000000000000")
  let assert Ok(key2) =
    key_nibbles.from_str("1200000000000000000000000000000000000000")
  assert key1 |> key_nibbles.common_prefix(key2)
    == key2 |> key_nibbles.common_prefix(key1)
  assert key1 |> key_nibbles.common_prefix(key2) |> key_nibbles.to_string()
    == "1"

  let assert Ok(key3) = key_nibbles.from_str("2dc")
  let assert Ok(key4) =
    key_nibbles.from_str("2da3183636aae21c2710b5bd4486903f8541fb80")
  assert Ok(key3 |> key_nibbles.common_prefix(key4))
    == key_nibbles.from_str("2d")

  let assert Ok(key5) = key_nibbles.from_str("2da")
  let assert Ok(key6) =
    key_nibbles.from_str("2da3183636aae21c2710b5bd4486903f8541fb80")
  assert Ok(key5 |> key_nibbles.common_prefix(key6))
    == key_nibbles.from_str("2da")
}

// Serialization tests

pub fn serde_empty_test() {
  assert key_nibbles.deserialize_all(<<0, 0>>) == Ok(key_nibbles.root())
  assert key_nibbles.root() |> key_nibbles.serialize_to_vec() == <<0, 0>>
}

pub fn serde_one_test() {
  let assert Ok(one0) = key_nibbles.from_str("0")
  let assert Ok(one1) = key_nibbles.from_str("1")
  let assert Ok(onef) = key_nibbles.from_str("f")
  assert key_nibbles.deserialize_all(<<0x01, 0x01, 0x00>>) == Ok(one0)
  assert key_nibbles.deserialize_all(<<0x01, 0x01, 0x10>>) == Ok(one1)
  assert key_nibbles.deserialize_all(<<0x01, 0x01, 0xf0>>) == Ok(onef)
  assert one0 |> key_nibbles.serialize_to_vec() == <<0x01, 0x01, 0x00>>
  assert one1 |> key_nibbles.serialize_to_vec() == <<0x01, 0x01, 0x10>>
  assert onef |> key_nibbles.serialize_to_vec() == <<0x01, 0x01, 0xf0>>
}

pub fn serde_two_test() {
  let assert Ok(two) = key_nibbles.from_str("9a")
  assert key_nibbles.deserialize_all(<<0x02, 0x01, 0x9a>>) == Ok(two)
  assert two |> key_nibbles.serialize_to_vec() == <<0x02, 0x01, 0x9a>>
}

pub fn serde_longer_test() {
  let assert Ok(longer1) = key_nibbles.from_str("68656c6c6f2c20776f726c6421")
  let assert Ok(longer2) = key_nibbles.from_str("68656c6c6f2c20776f726c64215")
  assert key_nibbles.deserialize_all(<<0x1a, 0x0d, "hello, world!">>)
    == Ok(longer1)
  assert key_nibbles.deserialize_all(<<0x1b, 0x0e, "hello, world!", 0x50>>)
    == Ok(longer2)
  assert longer1 |> key_nibbles.serialize_to_vec()
    == <<0x1a, 0x0d, "hello, world!">>
  assert longer2 |> key_nibbles.serialize_to_vec()
    == <<0x1b, 0x0e, "hello, world!", 0x50>>
}

pub fn serde_error_test() {
  assert key_nibbles.deserialize_all(<<>>)
    == Error("Invalid number: out of data")
  assert key_nibbles.deserialize_all(<<0x00>>)
    == Error("Invalid number: out of data")
  assert key_nibbles.deserialize_all(<<0xff>>)
    == Error("Invalid number: out of data")
  assert key_nibbles.deserialize_all(<<0x00, 0x01, 0x00>>)
    == Error("Invalid byte length: expected 0, got 1")
  assert key_nibbles.deserialize_all(<<0x01, 0x00, 0x00>>)
    == Error("Invalid byte length: expected 1, got 0")
}
