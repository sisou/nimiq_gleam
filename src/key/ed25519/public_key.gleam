import bindings/ed25519
import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/result
import key/ed25519/private_key.{type PrivateKey}
import utils/misc

const size = 32

pub opaque type PublicKey {
  PublicKey(buf: BitArray)
}

pub fn derive_key(private: PrivateKey) -> PublicKey {
  private
  |> private_key.serialize_to_bits()
  |> ed25519.derive_public_key()
  |> PublicKey()
}

pub fn deserialize(buf: BitArray) -> Result(#(PublicKey, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> ->
      Ok(#(PublicKey(bytes), rest))
    _ -> Error("Invalid Ed25519 public key: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(PublicKey, String) {
  case deserialize(buf) {
    Ok(#(key, <<>>)) -> Ok(key)
    Ok(_) -> Error("Invalid Ed25519 public key: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn from_hex(hex: String) -> Result(PublicKey, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid public key: not a valid hex encoding")
  }
}

pub fn from_base64(base64: String) -> Result(PublicKey, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid public key: not a valid base64 encoding")
  }
}

pub fn from_base64_url(base64_url: String) -> Result(PublicKey, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid public key: not a valid base64 url encoding")
  }
}

pub fn from_string(str: String) -> Result(PublicKey, String) {
  from_hex(str)
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
  |> result.map_error(fn(_) { "Invalid public key: unknown format" })
}

pub fn serialize(builder: BytesBuilder, key: PublicKey) -> BytesBuilder {
  builder |> bytes_builder.append(key.buf)
}

pub fn serialize_to_bits(key: PublicKey) -> BitArray {
  key.buf
}

pub fn to_hex(key: PublicKey) -> String {
  key |> serialize_to_bits() |> misc.to_hex()
}

pub fn to_base64(key: PublicKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(key: PublicKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}
