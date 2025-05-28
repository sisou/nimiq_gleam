import gleam/option.{None, Some}
import gleeunit/should

import key_nibbles

pub fn to_from_str_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")
  should.equal(
    key |> key_nibbles.to_string(),
    "cfb98637bcae43c13323eaa1731ced2b716962fd",
  )
  let assert Ok(key) = key_nibbles.from_str("")
  should.equal(key |> key_nibbles.to_string(), "ε")

  let assert Ok(key) = key_nibbles.from_str("ε")
  should.equal(key |> key_nibbles.to_string(), "ε")

  let assert Ok(key) = key_nibbles.from_str("1")
  should.equal(key |> key_nibbles.to_string(), "1")

  let assert Ok(key) = key_nibbles.from_str("23")
  should.equal(key |> key_nibbles.to_string(), "23")
}

pub fn sum_test() {
  let assert Ok(key1) = key_nibbles.from_str("cfb")
  let assert Ok(key2) = key_nibbles.from_str("986")

  should.equal(
    key1 |> key_nibbles.add(key2) |> key_nibbles.to_string(),
    "cfb986",
  )

  let assert Ok(key1) = key_nibbles.from_str("cfb9")
  let assert Ok(key2) = key_nibbles.from_str("8637")

  should.equal(
    key1 |> key_nibbles.add(key2) |> key_nibbles.to_string(),
    "cfb98637",
  )
}

pub fn get_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")

  should.equal(key |> key_nibbles.get(0), Some(12))
  should.equal(key |> key_nibbles.get(1), Some(15))
  should.equal(key |> key_nibbles.get(2), Some(11))
  should.equal(key |> key_nibbles.get(3), Some(9))
  should.equal(key |> key_nibbles.get(41), None)
  should.equal(key |> key_nibbles.get(42), None)
}

pub fn nibbles_slice_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")

  should.equal(key |> key_nibbles.slice(0, 1) |> key_nibbles.to_string(), "c")
  should.equal(key |> key_nibbles.slice(0, 2) |> key_nibbles.to_string(), "cf")
  should.equal(key |> key_nibbles.slice(0, 3) |> key_nibbles.to_string(), "cfb")
  should.equal(key |> key_nibbles.slice(1, 3) |> key_nibbles.to_string(), "fb")
  should.equal(
    key |> key_nibbles.slice(0, 41) |> key_nibbles.to_string(),
    "cfb98637bcae43c13323eaa1731ced2b716962fd",
  )
  should.equal(
    key |> key_nibbles.slice(1, 40) |> key_nibbles.to_string(),
    "fb98637bcae43c13323eaa1731ced2b716962fd",
  )
  should.equal(key |> key_nibbles.slice(2, 1) |> key_nibbles.to_string(), "ε")
  should.equal(key |> key_nibbles.slice(42, 43) |> key_nibbles.to_string(), "ε")
}

pub fn nibbles_suffix_test() {
  let assert Ok(key) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")

  should.equal(
    key |> key_nibbles.suffix(0) |> key_nibbles.to_string(),
    "cfb98637bcae43c13323eaa1731ced2b716962fd",
  )
  should.equal(
    key |> key_nibbles.suffix(1) |> key_nibbles.to_string(),
    "fb98637bcae43c13323eaa1731ced2b716962fd",
  )
  should.equal(
    key |> key_nibbles.suffix(2) |> key_nibbles.to_string(),
    "b98637bcae43c13323eaa1731ced2b716962fd",
  )
  should.equal(key |> key_nibbles.suffix(40) |> key_nibbles.to_string(), "ε")
  should.equal(key |> key_nibbles.suffix(42) |> key_nibbles.to_string(), "ε")
}

pub fn nibbles_is_prefix_of_test() {
  let assert Ok(key1) =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd")
  let assert Ok(key2) = key_nibbles.from_str("cfb")

  should.be_true(key2 |> key_nibbles.is_prefix_of(key1))
  should.be_false(key1 |> key_nibbles.is_prefix_of(key2))
}

pub fn nibbles_common_prefix_test() {
  let assert Ok(key1) =
    key_nibbles.from_str("1000000000000000000000000000000000000000")
  let assert Ok(key2) =
    key_nibbles.from_str("1200000000000000000000000000000000000000")
  should.equal(
    key1 |> key_nibbles.common_prefix(key2),
    key2 |> key_nibbles.common_prefix(key1),
  )
  should.equal(
    key1 |> key_nibbles.common_prefix(key2) |> key_nibbles.to_string(),
    "1",
  )

  let assert Ok(key3) = key_nibbles.from_str("2dc")
  let assert Ok(key4) =
    key_nibbles.from_str("2da3183636aae21c2710b5bd4486903f8541fb80")
  should.equal(
    Ok(key3 |> key_nibbles.common_prefix(key4)),
    key_nibbles.from_str("2d"),
  )

  let assert Ok(key5) = key_nibbles.from_str("2da")
  let assert Ok(key6) =
    key_nibbles.from_str("2da3183636aae21c2710b5bd4486903f8541fb80")
  should.equal(
    Ok(key5 |> key_nibbles.common_prefix(key6)),
    key_nibbles.from_str("2da"),
  )
}

// Serialization tests

pub fn serde_empty_test() {
  should.equal(key_nibbles.deserialize_all(<<0, 0>>), Ok(key_nibbles.root()))
  should.equal(key_nibbles.root() |> key_nibbles.serialize_to_vec(), <<0, 0>>)
}

pub fn serde_one_test() {
  let assert Ok(one0) = key_nibbles.from_str("0")
  let assert Ok(one1) = key_nibbles.from_str("1")
  let assert Ok(onef) = key_nibbles.from_str("f")
  should.equal(key_nibbles.deserialize_all(<<0x01, 0x01, 0x00>>), Ok(one0))
  should.equal(key_nibbles.deserialize_all(<<0x01, 0x01, 0x10>>), Ok(one1))
  should.equal(key_nibbles.deserialize_all(<<0x01, 0x01, 0xf0>>), Ok(onef))
  should.equal(one0 |> key_nibbles.serialize_to_vec(), <<0x01, 0x01, 0x00>>)
  should.equal(one1 |> key_nibbles.serialize_to_vec(), <<0x01, 0x01, 0x10>>)
  should.equal(onef |> key_nibbles.serialize_to_vec(), <<0x01, 0x01, 0xf0>>)
}

pub fn serde_two_test() {
  let assert Ok(two) = key_nibbles.from_str("9a")
  should.equal(key_nibbles.deserialize_all(<<0x02, 0x01, 0x9a>>), Ok(two))
  should.equal(two |> key_nibbles.serialize_to_vec(), <<0x02, 0x01, 0x9a>>)
}

pub fn serde_longer_test() {
  let assert Ok(longer1) = key_nibbles.from_str("68656c6c6f2c20776f726c6421")
  let assert Ok(longer2) = key_nibbles.from_str("68656c6c6f2c20776f726c64215")
  should.equal(
    key_nibbles.deserialize_all(<<0x1a, 0x0d, "hello, world!">>),
    Ok(longer1),
  )
  should.equal(
    key_nibbles.deserialize_all(<<0x1b, 0x0e, "hello, world!", 0x50>>),
    Ok(longer2),
  )
  should.equal(longer1 |> key_nibbles.serialize_to_vec(), <<
    0x1a, 0x0d, "hello, world!",
  >>)
  should.equal(longer2 |> key_nibbles.serialize_to_vec(), <<
    0x1b, 0x0e, "hello, world!", 0x50,
  >>)
}

pub fn serde_error_test() {
  should.be_error(key_nibbles.deserialize_all(<<>>))
  should.be_error(key_nibbles.deserialize_all(<<0x00>>))
  should.be_error(key_nibbles.deserialize_all(<<0xff>>))
  should.be_error(key_nibbles.deserialize_all(<<0x00, 0x01, 0x00>>))
  should.be_error(key_nibbles.deserialize_all(<<0x01, 0x00, 0x00>>))
}
