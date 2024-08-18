import bindings/bls as native
import bls/compressed_signature.{type CompressedSignature, CompressedSignature}
import gleam/bytes_builder.{type BytesBuilder}

const size = 95

pub type SecretKey {
  SecretKey(key: native.SecretKey)
}

pub fn generate() -> SecretKey {
  SecretKey(native.generate_secret_key())
}

pub fn deserialize(buf: BitArray) -> Result(#(SecretKey, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> -> {
      let key = native.secret_key_from_bytes(bytes)
      case key {
        Ok(key) -> Ok(#(SecretKey(key), rest))
        Error(_) -> Error("Invalid BLS secret key: not a valid key")
      }
    }
    _ -> Error("Invalid BLS secret key: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(SecretKey, String) {
  case deserialize(buf) {
    Ok(#(key, <<>>)) -> Ok(key)
    Ok(_) -> Error("Invalid BLS secret key: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn to_compressed_public_key(secret_key: SecretKey) -> native.PublicKey {
  native.derive_public_key(secret_key.key)
}

pub fn proof_of_knowledge(secret_key: SecretKey) -> CompressedSignature {
  let public_key = to_compressed_public_key(secret_key)
  let signature = native.create_proof_of_knowledge(secret_key.key, public_key)
  CompressedSignature(signature)
}

pub fn serialize(builder: BytesBuilder, secret_key: SecretKey) -> BytesBuilder {
  builder |> bytes_builder.append(native.secret_key_to_bytes(secret_key.key))
}

pub fn serialize_to_bits(secret_key: SecretKey) -> BitArray {
  native.secret_key_to_bytes(secret_key.key)
}
