import account/address.{type Address}
import bindings/blake2
import gleam/bit_array
import gleam/string
import key/ed25519/public_key as ed25519_public_key
import transaction/enums.{
  type SignatureProofAlgorithm, ES256Algorithm, Ed25519Algorithm,
}

pub type PublicKey {
  EdDsaPublicKey(key: ed25519_public_key.PublicKey)
  EcDsaPublicKey(buf: BitArray)
}

pub fn deserialize_typed(
  buf: BitArray,
  typ: SignatureProofAlgorithm,
) -> Result(#(PublicKey, BitArray), String) {
  case typ {
    Ed25519Algorithm -> deserialize_eddsa(buf)
    ES256Algorithm -> deserialize_ecdsa(buf)
  }
}

fn deserialize_eddsa(buf: BitArray) -> Result(#(PublicKey, BitArray), String) {
  case ed25519_public_key.deserialize(buf) {
    Ok(#(public_key, rest)) -> Ok(#(EdDsaPublicKey(public_key), rest))
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

pub fn to_address(public_key: PublicKey) -> Address {
  let address =
    public_key
    |> serialize()
    |> blake2.hash2b(32)
    |> address.from_hash()

  case address {
    Ok(address) -> address
    Error(_) -> panic as "Could not derive address from public key"
  }
}

pub fn serialize(public_key: PublicKey) -> BitArray {
  case public_key {
    EdDsaPublicKey(key) -> ed25519_public_key.serialize(key)
    EcDsaPublicKey(buf) -> buf
  }
}

pub fn to_hex(public_key: PublicKey) -> String {
  public_key |> serialize() |> bit_array.base16_encode() |> string.lowercase()
}

pub fn to_base64(public_key: PublicKey) -> String {
  public_key |> serialize() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(public_key: PublicKey) -> String {
  public_key |> serialize() |> bit_array.base64_url_encode(True)
}
