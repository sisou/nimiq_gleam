import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import utils/base32
import utils/misc

const size = 20

const ccode = "NQ"

const nimiq_alphabet = "0123456789ABCDEFGHJKLMNPQRSTUVXY"

pub opaque type Address {
  Address(buf: BitArray)
}

pub fn zero() -> Address {
  Address(<<0:unit(8)-size(size)>>)
}

pub fn staking_contract() -> Address {
  Address(<<1:unit(8)-size(size)>>)
}

pub fn deserialize(buf: BitArray) -> Result(#(Address, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> -> Ok(#(Address(bytes), rest))
    _ -> Error("Invalid address: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(Address, String) {
  case deserialize(buf) {
    Ok(#(address, <<>>)) -> Ok(address)
    Ok(_) -> Error("Invalid address: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn from_hash(hash: BitArray) -> Result(Address, String) {
  let buf = hash |> bit_array.slice(0, size)

  case buf {
    Ok(buf) -> Ok(Address(buf))
    Error(_) -> Error("Invalid address: hash too short")
  }
}

pub fn from_hex(hex: String) -> Result(Address, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid hex encoding")
  }
}

pub fn from_base64(base64: String) -> Result(Address, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid base64 encoding")
  }
}

pub fn from_base64_url(base64_url: String) -> Result(Address, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid base64 url encoding")
  }
}

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
  let encoded = string.drop_left(normalized, 4)
  use _ <- result.try(case
    iban_check(encoded <> string.slice(normalized, 0, 4)) == 1
  {
    False -> Error("Invalid address: wrong checksum")
    True -> Ok(Nil)
  })

  case base32.decode(encoded, nimiq_alphabet) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid address: not a valid user friendly encoding")
  }
}

pub fn from_string(str: String) -> Result(Address, String) {
  from_user_friendly_address(str)
  |> result.lazy_or(fn() { from_hex(str) })
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
  |> result.map_error(fn(_) { "Invalid address: unknown format" })
}

pub fn serialize(builder: BytesBuilder, address: Address) -> BytesBuilder {
  builder |> bytes_builder.append(address.buf)
}

pub fn serialize_to_bits(address: Address) -> BitArray {
  address.buf
}

pub fn to_hex(address: Address) -> String {
  address |> serialize_to_bits() |> misc.to_hex()
}

pub fn to_base64(address: Address) -> String {
  address |> serialize_to_bits() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(address: Address) -> String {
  address |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}

pub fn to_user_friendly_address(address: Address) -> String {
  let encoded = base32.encode(address.buf, nimiq_alphabet)
  let check =
    { "00" <> int.to_string(98 - iban_check(encoded <> ccode <> "00")) }
    |> string.slice(-2, 2)

  let address = ccode <> check <> encoded

  // Add spaces between every 4 characters
  list.range(0, 8)
  |> list.map(fn(i) { string.slice(address, i * 4, 4) })
  |> string.join(" ")
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

  let range =
    num
    |> string.length()
    // Convert to float for lossless division
    |> int.to_float()
    |> float.divide(6.0)
    // float.divide returns an Error only when dividing by 0, which we don't do here
    |> misc.unwrap()
    |> float.ceiling()
    // Convert back to int
    |> float.round()
    |> int.subtract(1)
    // Create a list of numbers starting at 0 until the result from above
    |> list.range(0, _)

  let tmp =
    range
    |> list.fold("", fn(tmp, i) {
      { tmp <> string.slice(num, i * 6, 6) }
      |> int.parse()
      // We know that the string is only numbers, so parsing cannot fail
      |> misc.unwrap()
      |> int.modulo(97)
      // int.modulo returns an Error only when dividing by 0, which we don't do here
      |> misc.unwrap()
      |> int.to_string()
    })

  // We know that the string is only numbers, so parsing cannot fail
  int.parse(tmp) |> misc.unwrap()
}
