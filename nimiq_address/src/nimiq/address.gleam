import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import nimiq/base32

const size = 20

const ccode = "NQ"

const nimiq_alphabet = "0123456789ABCDEFGHJKLMNPQRSTUVXY"

pub opaque type Address {
  Address(buf: BitArray)
}

/// Creates an Address with all bytes set to zero (burn address).
pub fn zero() -> Address {
  Address(<<0:unit(8)-size(size)>>)
}

/// Creates the staking contract address (all bytes zero except the last byte set to 1).
pub fn staking_contract() -> Address {
  Address(<<1:unit(8)-size(size)>>)
}

/// Deserializes an Address from a BitArray.
pub fn deserialize(buf: BitArray) -> Result(#(Address, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> -> Ok(#(Address(bytes), rest))
    _ -> Error("Invalid address: out of data")
  }
}

/// Deserializes an Address from a BitArray, ensuring that all bytes are consumed.
pub fn deserialize_all(buf: BitArray) -> Result(Address, String) {
  case deserialize(buf) {
    Ok(#(address, <<>>)) -> Ok(address)
    Ok(_) -> Error("Invalid address: trailing bytes")
    Error(err) -> Error(err)
  }
}

/// Creates an Address from a hash (BitArray). The hash must be at least 20 bytes long.
pub fn from_hash(hash: BitArray) -> Result(Address, String) {
  let buf = hash |> bit_array.slice(0, size)

  case buf {
    Ok(buf) -> Ok(Address(buf))
    Error(_) -> Error("Invalid address: hash too short")
  }
}

/// Creates an Address from a hex string. The string must represent exactly 20 bytes.
pub fn from_hex(hex: String) -> Result(Address, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid hex encoding")
  }
}

/// Creates an Address from a base64 string. The string must represent exactly 20 bytes.
pub fn from_base64(base64: String) -> Result(Address, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid base64 encoding")
  }
}

/// Creates an Address from a base64-url string. The string must represent exactly 20 bytes.
pub fn from_base64_url(base64_url: String) -> Result(Address, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid base64 url encoding")
  }
}

/// Creates an Address from a user friendly address string.
pub fn from_user_friendly_address(str: String) -> Result(Address, String) {
  let normalized = str |> string.replace(" ", "") |> string.uppercase()

  use _ <- result.try(case string.slice(normalized, 0, 2) == ccode {
    False -> Error("Invalid address: wrong country code")
    True -> Ok(Nil)
  })
  use _ <- result.try(case string.length(normalized) == 36 {
    False -> Error("Invalid address: wrong length")
    True -> Ok(Nil)
  })

  // Calculate and check the checksum
  let encoded = string.drop_start(normalized, 4)
  use _ <- result.try(
    case iban_check(encoded <> string.slice(normalized, 0, 4)) == 1 {
      False -> Error("Invalid address: wrong checksum")
      True -> Ok(Nil)
    },
  )

  case base32.decode(encoded, nimiq_alphabet) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid user friendly encoding")
  }
}

/// Creates an Address from a user friendly address string with a custom country code.
pub fn from_user_friendly_address_ccode(
  str: String,
  ccode: String,
) -> Result(Address, String) {
  let normalized = str |> string.replace(" ", "") |> string.uppercase()

  use _ <- result.try(case string.slice(normalized, 0, 2) == ccode {
    False -> Error("Invalid address: wrong country code")
    True -> Ok(Nil)
  })
  use _ <- result.try(case string.length(normalized) == 36 {
    False -> Error("Invalid address: wrong length")
    True -> Ok(Nil)
  })

  // Calculate and check the checksum
  let encoded = string.drop_start(normalized, 4)
  use _ <- result.try(
    case iban_check(encoded <> string.slice(normalized, 0, 4)) == 1 {
      False -> Error("Invalid address: wrong checksum")
      True -> Ok(Nil)
    },
  )

  case base32.decode(encoded, nimiq_alphabet) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid user friendly encoding")
  }
}

/// Creates an Address from a string in any supported format.
pub fn from_string(str: String) -> Result(Address, String) {
  from_user_friendly_address(str)
  |> result.lazy_or(fn() { from_hex(str) })
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
  |> result.map_error(fn(_) { "Invalid address: unknown format" })
}

/// Serializes an Address into a BytesTree.
pub fn serialize(builder: BytesTree, address: Address) -> BytesTree {
  builder |> bytes_tree.append(address.buf)
}

/// Serializes an Address to a BitArray.
pub fn serialize_to_bits(address: Address) -> BitArray {
  address.buf
}

/// Converts an Address to its hex representation.
pub fn to_hex(address: Address) -> String {
  address
  |> serialize_to_bits()
  |> bit_array.base16_encode()
  |> string.lowercase()
}

/// Converts an Address to its base64 representation.
pub fn to_base64(address: Address) -> String {
  address |> serialize_to_bits() |> bit_array.base64_encode(True)
}

/// Converts an Address to its base64-url representation.
pub fn to_base64_url(address: Address) -> String {
  address |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}

/// Converts an Address to its user friendly address representation.
pub fn to_user_friendly_address(address: Address) -> String {
  let encoded = base32.encode(address.buf, nimiq_alphabet)
  let check =
    { "00" <> int.to_string(98 - iban_check(encoded <> ccode <> "00")) }
    |> string.slice(-2, 2)

  let address = ccode <> check <> encoded

  // Add spaces between every 4 characters
  int.range(1, 9, string.slice(address, 0, 4), fn(acc, i) {
    acc <> " " <> string.slice(address, i * 4, 4)
  })
}

/// Converts an Address to its user friendly address representation with a custom country code.
pub fn to_user_friendly_address_ccode(
  address: Address,
  ccode: String,
) -> String {
  let encoded = base32.encode(address.buf, nimiq_alphabet)
  let check =
    { "00" <> int.to_string(98 - iban_check(encoded <> ccode <> "00")) }
    |> string.slice(-2, 2)

  let address = ccode <> check <> encoded

  // Add spaces between every 4 characters
  int.range(1, 9, string.slice(address, 0, 4), fn(acc, i) {
    acc <> " " <> string.slice(address, i * 4, 4)
  })
}

fn iban_check(str: String) -> Int {
  let num =
    str
    |> string.uppercase()
    |> string.to_utf_codepoints()
    |> list.zip(string.split(str, ""))
    |> list.map(fn(tuple) {
      case string.utf_codepoint_to_int(tuple.0) {
        code if code >= 48 && code <= 57 -> tuple.1
        code -> int.to_string(code - 55)
      }
    })
    |> string.join("")

  let tmp =
    num
    |> string.length()
    // Convert to float for lossless division
    |> int.to_float()
    |> float.divide(6.0)
    // float.divide returns an Error only when dividing by 0, which we don't do here
    |> unwrap()
    |> float.ceiling()
    // Convert back to int
    |> float.round()
    |> int.range(0, _, "", fn(tmp, i) {
      { tmp <> string.slice(num, i * 6, 6) }
      |> int.parse()
      // We know that the string is only numbers, so parsing cannot fail
      |> unwrap()
      |> int.modulo(97)
      // int.modulo returns an Error only when dividing by 0, which we don't do here
      |> unwrap()
      |> int.to_string()
    })

  // We know that the string is only numbers, so parsing cannot fail
  int.parse(tmp) |> unwrap()
}

fn unwrap(res: Result(a, _)) -> a {
  case res {
    Ok(a) -> a
    Error(_) -> panic as "Called unwrap on an Error value"
  }
}
