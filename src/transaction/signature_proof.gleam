import gleam/bit_array
import gleam/bytes_builder
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import key/public_key.{type PublicKey, EcDsaPublicKey, EdDsaPublicKey}
import key/signature.{type Signature}
import merkle/merkle_path.{type MerklePath}
import transaction/enums.{
  type SignatureProofAlgorithm, ES256Algorithm, Ed25519Algorithm,
}
import transaction/flags.{type SignatureProofFlags, WebauthnFieldsFlag}

pub type SignatureProof {
  SignatureProof(
    public_key: PublicKey,
    merkle_path: MerklePath,
    signature: Signature,
    // TODO: Add WebAuthnFields type
    webauthn_fields: Option(BitArray),
  )
}

pub fn single_sig(public_key: PublicKey, signature: Signature) -> SignatureProof {
  SignatureProof(public_key, merkle_path.empty(), signature, None)
}

pub fn single_sig_webauthn(
  public_key: PublicKey,
  signature: Signature,
  webauthn_fields: BitArray,
) -> SignatureProof {
  SignatureProof(
    public_key,
    merkle_path.empty(),
    signature,
    Some(webauthn_fields),
  )
}

pub fn deserialize(buf: BitArray) -> Result(#(SignatureProof, BitArray), String) {
  use #(#(signature_alg, flags), rest) <- result.try(
    deserialize_type_and_flags_byte(buf),
  )
  use #(public_key, rest) <- result.try(public_key.deserialize_typed(
    rest,
    signature_alg,
  ))
  use #(merkle_path, rest) <- result.try(merkle_path.deserialize(rest))
  use #(signature, rest) <- result.try(signature.deserialize_typed(
    rest,
    signature_alg,
  ))
  case flags {
    None ->
      Ok(#(SignatureProof(public_key, merkle_path, signature, None), rest))
    Some(WebauthnFieldsFlag) ->
      Ok(
        #(SignatureProof(public_key, merkle_path, signature, Some(rest)), <<>>),
      )
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(SignatureProof, String) {
  case deserialize(buf) {
    Ok(#(proof, <<>>)) -> Ok(proof)
    Ok(_) -> Error("Invalid signature proof: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn parse_type_and_flags_byte(
  byte: Int,
) -> Result(#(SignatureProofAlgorithm, Option(SignatureProofFlags)), String) {
  use signature_alg <- result.try(
    int.bitwise_and(byte, 0b1111) |> enums.to_signature_algorithm(),
  )
  use flags <- result.try(
    int.bitwise_shift_right(byte, 4) |> flags.to_signature_proof_flags(),
  )
  Ok(#(signature_alg, flags))
}

pub fn make_type_and_flags_byte(proof: SignatureProof) -> Int {
  let signature_alg =
    case proof.public_key {
      EdDsaPublicKey(_) -> Ed25519Algorithm
      EcDsaPublicKey(_) -> ES256Algorithm
    }
    |> enums.from_signature_algorithm()

  let flags =
    case proof.webauthn_fields {
      None -> None
      Some(_) -> Some(WebauthnFieldsFlag)
    }
    |> flags.from_signature_proof_flags()

  int.bitwise_or(int.bitwise_shift_left(flags, 4), signature_alg)
}

pub fn serialize(proof: SignatureProof) -> BitArray {
  bytes_builder.new()
  |> bytes_builder.append(<<make_type_and_flags_byte(proof)>>)
  |> bytes_builder.append(public_key.serialize(proof.public_key))
  |> bytes_builder.append(merkle_path.serialize(proof.merkle_path))
  |> bytes_builder.append(signature.serialize(proof.signature))
  |> bytes_builder.append_builder(case proof.webauthn_fields {
    Some(fields) -> {
      bytes_builder.new()
      |> bytes_builder.append(<<bit_array.byte_size(fields):8>>)
      |> bytes_builder.append(fields)
    }
    None -> bytes_builder.new()
  })
  |> bytes_builder.to_bit_array()
}

pub fn deserialize_type_and_flags_byte(
  buf: BitArray,
) -> Result(
  #(#(SignatureProofAlgorithm, Option(SignatureProofFlags)), BitArray),
  String,
) {
  case buf {
    <<byte:8, rest:bits>> -> {
      case parse_type_and_flags_byte(byte) {
        Ok(type_and_flags) -> Ok(#(type_and_flags, rest))
        Error(err) -> Error(err)
      }
    }
    _ -> Error("Invalid signature proof: out of data")
  }
}

pub fn deserialize_webauthn_fields(
  buf: BitArray,
) -> Result(#(BitArray, BitArray), String) {
  case buf {
    <<len:8, rest:bits>> -> {
      case rest {
        <<fields:unit(8)-size(len)-bytes, rest:bits>> -> Ok(#(fields, rest))
        _ -> Error("Invalid signature proof webauthn fields: out of data")
      }
    }
    _ -> Error("Invalid signature proof webauthn fields: out of data")
  }
}
