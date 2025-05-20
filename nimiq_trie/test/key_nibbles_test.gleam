import gleam/option.{None, Some}
import gleeunit/should
import key_nibbles
import utils.{unwrap}

pub fn to_from_str_test() {
  let key =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd") |> unwrap()
  should.equal(
    key |> key_nibbles.to_string(),
    "cfb98637bcae43c13323eaa1731ced2b716962fd",
  )
  let key = key_nibbles.from_str("") |> unwrap()
  should.equal(key |> key_nibbles.to_string(), "ε")

  let key = key_nibbles.from_str("ε") |> unwrap()
  should.equal(key |> key_nibbles.to_string(), "ε")

  let key = key_nibbles.from_str("1") |> unwrap()
  should.equal(key |> key_nibbles.to_string(), "1")

  let key = key_nibbles.from_str("23") |> unwrap()
  should.equal(key |> key_nibbles.to_string(), "23")
}

pub fn sum_test() {
  let key1 = key_nibbles.from_str("cfb") |> unwrap()
  let key2 = key_nibbles.from_str("986") |> unwrap()

  should.equal(
    key1 |> key_nibbles.add(key2) |> key_nibbles.to_string(),
    "cfb986",
  )

  let key1 = key_nibbles.from_str("cfb9") |> unwrap()
  let key2 = key_nibbles.from_str("8637") |> unwrap()

  should.equal(
    key1 |> key_nibbles.add(key2) |> key_nibbles.to_string(),
    "cfb98637",
  )
}

pub fn get_test() {
  let key =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd") |> unwrap()

  should.equal(key |> key_nibbles.get(0), Some(12))
  should.equal(key |> key_nibbles.get(1), Some(15))
  should.equal(key |> key_nibbles.get(2), Some(11))
  should.equal(key |> key_nibbles.get(3), Some(9))
  should.equal(key |> key_nibbles.get(41), None)
  should.equal(key |> key_nibbles.get(42), None)
}

pub fn nibbles_slice_test() {
  let key =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd") |> unwrap()

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
  let key =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd") |> unwrap()

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
  let key1 =
    key_nibbles.from_str("cfb98637bcae43c13323eaa1731ced2b716962fd") |> unwrap()
  let key2 = key_nibbles.from_str("cfb") |> unwrap()

  should.be_true(key2 |> key_nibbles.is_prefix_of(key1))
  should.be_false(key1 |> key_nibbles.is_prefix_of(key2))
}

pub fn nibbles_common_prefix_test() {
  let key1 =
    key_nibbles.from_str("1000000000000000000000000000000000000000") |> unwrap()
  let key2 =
    key_nibbles.from_str("1200000000000000000000000000000000000000") |> unwrap()
  should.equal(
    key1 |> key_nibbles.common_prefix(key2),
    key2 |> key_nibbles.common_prefix(key1),
  )
  should.equal(
    key1 |> key_nibbles.common_prefix(key2) |> key_nibbles.to_string(),
    "1",
  )

  let key3 = key_nibbles.from_str("2dc") |> unwrap()
  let key4 =
    key_nibbles.from_str("2da3183636aae21c2710b5bd4486903f8541fb80") |> unwrap()
  should.equal(
    key3 |> key_nibbles.common_prefix(key4),
    key_nibbles.from_str("2d") |> unwrap(),
  )

  let key5 = key_nibbles.from_str("2da") |> unwrap()
  let key6 =
    key_nibbles.from_str("2da3183636aae21c2710b5bd4486903f8541fb80") |> unwrap()
  should.equal(
    key5 |> key_nibbles.common_prefix(key6),
    key_nibbles.from_str("2da") |> unwrap(),
  )
}
