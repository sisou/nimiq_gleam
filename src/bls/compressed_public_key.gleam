import bindings/bls as native
import bls/secret_key.{type SecretKey}
import gleam/bytes_builder.{type BytesBuilder}

const size = 285

pub type CompressedPublicKey {
  CompressedPublicKey(key: native.PublicKey)
}

pub fn deserialize(
  buf: BitArray,
) -> Result(#(CompressedPublicKey, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> -> {
      let key = native.public_key_from_bytes(bytes)
      case key {
        Ok(key) -> Ok(#(CompressedPublicKey(key), rest))
        Error(_) -> Error("Invalid BLS public key: not a key")
      }
    }
    _ -> Error("Invalid BLS public key: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(CompressedPublicKey, String) {
  case deserialize(buf) {
    Ok(#(key, <<>>)) -> Ok(key)
    Ok(_) -> Error("Invalid BLS public key: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn derive_key(public_key: SecretKey) -> CompressedPublicKey {
  let public = native.derive_public_key(public_key.key)
  CompressedPublicKey(public)
}

pub fn serialize(
  builder: BytesBuilder,
  public_key: CompressedPublicKey,
) -> BytesBuilder {
  builder |> bytes_builder.append(native.public_key_to_bytes(public_key.key))
}

pub fn serialize_to_bits(public_key: CompressedPublicKey) -> BitArray {
  native.public_key_to_bytes(public_key.key)
}
