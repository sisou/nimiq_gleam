import gleam/bit_array
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

const size = 20

const ccode = "NQ"

const nimiq_alphabet = "0123456789ABCDEFGHJKLMNPQRSTUVXY"

pub opaque type Address {
  Address(buf: BitArray)
}

pub fn unserialize(buf: BitArray) -> Result(Address, String) {
  case bit_array.byte_size(buf) == size {
    True -> Ok(Address(buf))
    False -> Error("Invalid address length")
  }
}

pub fn from_hex(hex: String) -> Result(Address, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> unserialize(buf)
    Error(_) -> Error("Failed to parse input, not a valid hex encoding")
  }
}

pub fn from_base64(base64: String) -> Result(Address, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> unserialize(buf)
    Error(_) -> Error("Failed to parse input, not a valid base64 encoding")
  }
}

pub fn from_base64_url(base64_url: String) -> Result(Address, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> unserialize(buf)
    Error(_) -> Error("Failed to parse input, not a valid base64 url encoding")
  }
}

pub fn from_user_friendly_address(str: String) -> Result(Address, String) {
  todo
}

pub fn from_string(str: String) -> Result(Address, String) {
  // from_user_friendly_address(str)
  // |> result.lazy_or(fn() { from_hex(str) })
  from_hex(str)
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
}

pub fn serialize(address: Address) -> BitArray {
  address.buf
}

pub fn to_hex(address: Address) -> String {
  bit_array.base16_encode(address.buf)
}

pub fn to_base64(address: Address) -> String {
  bit_array.base64_encode(address.buf, True)
}

pub fn to_base64_url(address: Address) -> String {
  bit_array.base64_url_encode(address.buf, True)
}

pub fn to_user_friendly_address(address: Address) -> String {
  let base32 = "00000000000000000000000000000000"
  // TODO
  let check =
    { "00" <> int.to_string(98 - iban_check(base32 <> ccode <> "00")) }
    |> string.slice(-2, 2)

  let address = ccode <> check <> base32

  // Add spaces between every 4 characters
  list.range(0, 8)
  |> list.map(fn(i) { string.slice(address, i * 4, 4) })
  |> string.join(" ")
}

fn iban_check(str: String) -> Int {
  let num =
    string.uppercase(str)
    |> string.to_utf_codepoints()
    |> list.zip(string.split(str, ""))
    |> list.map(fn(tuple) {
      case string.utf_codepoint_to_int(tuple.0) {
        code if code >= 48 && code <= 57 -> tuple.1
        code -> int.to_string(code - 55)
      }
    })
    |> string.join("")

  let range =
    string.length(num)
    // Convert to float for lossless division
    |> int.to_float()
    |> float.divide(6.0)
    // float.divide returns an Error only when dividing by 0, which we don't do here
    |> result.unwrap(0.0)
    |> float.ceiling()
    // Convert back to int
    |> float.round()
    |> int.subtract(1)
    // Create a list of numbers starting at 0 until the result from above
    |> list.range(0, _)

  let tmp =
    list.fold(range, "", fn(tmp, i) {
      { tmp <> string.slice(num, i * 6, 6) }
      |> int.parse()
      // We know that the string is only numbers, so parsing should never fail
      |> result.unwrap(0)
      |> int.modulo(97)
      // int.modulo returns an Error only when dividing by 0, which we don't do here
      |> result.unwrap(0)
      |> int.to_string()
    })

  int.parse(tmp) |> result.unwrap(0)
}
