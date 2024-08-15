import account/address.{type Address}
import bindings/blake2
import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import key/ed25519/public_key as ed25519_public_key
import transaction/signature_proof_algorithm.{type SignatureProofAlgorithm}
import utils/misc

pub type PublicKey {
  EdDsaPublicKey(key: ed25519_public_key.PublicKey)
  EcDsaPublicKey(buf: BitArray)
}

pub fn default() -> PublicKey {
  EdDsaPublicKey(ed25519_public_key.default())
}

pub fn deserialize_typed(
  buf: BitArray,
  typ: SignatureProofAlgorithm,
) -> Result(#(PublicKey, BitArray), String) {
  case typ {
    signature_proof_algorithm.Ed25519 -> deserialize_eddsa(buf)
    signature_proof_algorithm.ES256 -> deserialize_ecdsa(buf)
  }
}

fn deserialize_eddsa(buf: BitArray) -> Result(#(PublicKey, BitArray), String) {
  case ed25519_public_key.deserialize(buf) {
    Ok(#(key, rest)) -> Ok(#(EdDsaPublicKey(key), rest))
    Error(err) -> Error(err)
  }
}

fn deserialize_ecdsa(buf: BitArray) -> Result(#(PublicKey, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(33)-bytes, rest:bits>> -> {
      Ok(#(EcDsaPublicKey(bytes), rest))
    }
    _ -> Error("Invalid ECDSA public key: out of data")
  }
}

pub fn to_address(key: PublicKey) -> Address {
  let assert Ok(address) =
    key
    |> serialize_to_bits()
    |> blake2.hash2b(32)
    |> address.from_hash()

  address
}

pub fn serialize(builder: BytesBuilder, key: PublicKey) -> BytesBuilder {
  case key {
    EdDsaPublicKey(key) -> builder |> ed25519_public_key.serialize(key)
    EcDsaPublicKey(buf) -> builder |> bytes_builder.append(buf)
  }
}

pub fn serialize_to_bits(key: PublicKey) -> BitArray {
  case key {
    EdDsaPublicKey(key) -> ed25519_public_key.serialize_to_bits(key)
    EcDsaPublicKey(buf) -> buf
  }
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
