import bindings/ed25519
import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/result
import utils/misc

const size = 32

pub opaque type PrivateKey {
  PrivateKey(buf: BitArray)
}

pub fn generate() -> PrivateKey {
  let #(secret, _) = ed25519.generate_key_pair()
  PrivateKey(secret)
}

pub fn deserialize(buf: BitArray) -> Result(#(PrivateKey, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> ->
      Ok(#(PrivateKey(bytes), rest))
    _ -> Error("Invalid address: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(PrivateKey, String) {
  case deserialize(buf) {
    Ok(#(key, <<>>)) -> Ok(key)
    Ok(_) -> Error("Invalid public key: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn from_hex(hex: String) -> Result(PrivateKey, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid private key: not a valid hex encoding")
  }
}

pub fn from_base64(base64: String) -> Result(PrivateKey, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid private key: not a valid base64 encoding")
  }
}

pub fn from_base64_url(base64_url: String) -> Result(PrivateKey, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid private key: not a valid base64 url encoding")
  }
}

pub fn from_string(str: String) -> Result(PrivateKey, String) {
  from_hex(str)
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
  |> result.map_error(fn(_) { "Invalid private key: unknown format" })
}

pub fn serialize(builder: BytesBuilder, key: PrivateKey) -> BytesBuilder {
  builder |> bytes_builder.append(key.buf)
}

pub fn serialize_to_bits(key: PrivateKey) -> BitArray {
  key.buf
}

pub fn to_hex(key: PrivateKey) -> String {
  key |> serialize_to_bits() |> misc.to_hex()
}

pub fn to_base64(key: PrivateKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(key: PrivateKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}
