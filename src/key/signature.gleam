import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import key/ed25519/private_key as ed25519_private_key
import key/ed25519/public_key as ed25519_public_key
import key/ed25519/signature as ed25519_signature
import transaction/signature_proof_algorithm.{type SignatureProofAlgorithm}
import utils/misc

pub type Signature {
  EdDsaSignature(sig: ed25519_signature.Signature)
  EcDsaSignature(buf: BitArray)
}

pub fn create(
  private: ed25519_private_key.PrivateKey,
  public: ed25519_public_key.PublicKey,
  data: BitArray,
) -> Signature {
  ed25519_signature.create(private, public, data) |> EdDsaSignature
}

pub fn deserialize_typed(
  buf: BitArray,
  typ: SignatureProofAlgorithm,
) -> Result(#(Signature, BitArray), String) {
  case typ {
    signature_proof_algorithm.Ed25519 -> deserialize_eddsa(buf)
    signature_proof_algorithm.ES256 -> deserialize_ecdsa(buf)
  }
}

fn deserialize_eddsa(buf: BitArray) -> Result(#(Signature, BitArray), String) {
  case ed25519_signature.deserialize(buf) {
    Ok(#(public_key, rest)) -> Ok(#(EdDsaSignature(public_key), rest))
    Error(err) -> Error(err)
  }
}

fn deserialize_ecdsa(buf: BitArray) -> Result(#(Signature, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(64)-bytes, rest:bits>> -> {
      Ok(#(EcDsaSignature(bytes), rest))
    }
    _ -> Error("Invalid public key: out of data")
  }
}

pub fn serialize(builder: BytesBuilder, sig: Signature) -> BytesBuilder {
  case sig {
    EdDsaSignature(sig) -> builder |> ed25519_signature.serialize(sig)
    EcDsaSignature(buf) -> builder |> bytes_builder.append(buf)
  }
}

pub fn serialize_to_bits(sig: Signature) -> BitArray {
  case sig {
    EdDsaSignature(sig) -> ed25519_signature.serialize_to_bits(sig)
    EcDsaSignature(buf) -> buf
  }
}

pub fn to_hex(sig: Signature) -> String {
  sig |> serialize_to_bits() |> misc.to_hex()
}

pub fn to_base64(sig: Signature) -> String {
  sig |> serialize_to_bits() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(sig: Signature) -> String {
  sig |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}
