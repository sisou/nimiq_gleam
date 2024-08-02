import gleam/bit_array
import gleam/string
import key/ed25519/private_key as ed25519_private_key
import key/ed25519/public_key as ed25519_public_key
import key/ed25519/signature as ed25519_signature
import transaction/enums.{
  type SignatureProofAlgorithm, ES256Algorithm, Ed25519Algorithm,
}

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
    Ed25519Algorithm -> deserialize_eddsa(buf)
    ES256Algorithm -> deserialize_ecdsa(buf)
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

pub fn serialize(signature: Signature) -> BitArray {
  case signature {
    EdDsaSignature(sig) -> ed25519_signature.serialize(sig)
    EcDsaSignature(buf) -> buf
  }
}

pub fn to_hex(signature: Signature) -> String {
  signature |> serialize() |> bit_array.base16_encode() |> string.lowercase()
}

pub fn to_base64(signature: Signature) -> String {
  signature |> serialize() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(signature: Signature) -> String {
  signature |> serialize() |> bit_array.base64_url_encode(True)
}
