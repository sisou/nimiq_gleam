import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import nimiq/key/ed25519/private_key as ed25519_private_key
import nimiq/key/ed25519/public_key as ed25519_public_key
import nimiq/key/ed25519/signature as ed25519_signature
import nimiq/transaction/signature_proof_algorithm.{type SignatureProofAlgorithm}
import nimiq/utils/misc

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

pub fn default() -> Signature {
  EdDsaSignature(ed25519_signature.default())
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

pub fn serialize(builder: BytesTree, sig: Signature) -> BytesTree {
  case sig {
    EdDsaSignature(sig) -> builder |> ed25519_signature.serialize(sig)
    EcDsaSignature(buf) -> builder |> bytes_tree.append(buf)
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
