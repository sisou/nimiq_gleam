import gleam/bytes_builder.{type BytesBuilder}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import key/public_key.{type PublicKey, EcDsaPublicKey, EdDsaPublicKey}
import key/signature.{type Signature}
import merkle/merkle_path.{type MerklePath}
import transaction/signature_proof_algorithm.{type SignatureProofAlgorithm}
import transaction/signature_proof_flags.{type SignatureProofFlags}
import utils/serde

pub type SignatureProof {
  SignatureProof(
    public_key: PublicKey,
    merkle_path: MerklePath,
    signature: Signature,
    // TODO: Add WebAuthnFields type
    webauthn_fields: Option(WebauthnFields),
  )
}

pub type WebauthnFields {
  WebauthnFields(
    origin_json_str: String,
    has_cross_origin_field: Bool,
    client_data_extra_json: String,
    authenticator_data_suffix: BitArray,
  )
}

pub fn single_sig(public_key: PublicKey, signature: Signature) -> SignatureProof {
  SignatureProof(public_key, merkle_path.empty(), signature, None)
}

pub fn single_sig_webauthn(
  public_key: PublicKey,
  signature: Signature,
  webauthn_fields: WebauthnFields,
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
    Some(signature_proof_flags.WebauthnFields) -> {
      use #(fields, rest) <- result.try(deserialize_webauthn_fields(rest))
      Ok(#(
        SignatureProof(public_key, merkle_path, signature, Some(fields)),
        rest,
      ))
    }
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
    int.bitwise_and(byte, 0b1111) |> signature_proof_algorithm.from_int(),
  )
  use flags <- result.try(
    int.bitwise_shift_right(byte, 4) |> signature_proof_flags.from_int(),
  )
  Ok(#(signature_alg, flags))
}

pub fn make_type_and_flags_byte(proof: SignatureProof) -> Int {
  let signature_alg =
    case proof.public_key {
      EdDsaPublicKey(_) -> signature_proof_algorithm.Ed25519
      EcDsaPublicKey(_) -> signature_proof_algorithm.ES256
    }
    |> signature_proof_algorithm.to_int()

  let flags =
    case proof.webauthn_fields {
      None -> None
      Some(_) -> Some(signature_proof_flags.WebauthnFields)
    }
    |> signature_proof_flags.to_int()

  int.bitwise_or(int.bitwise_shift_left(flags, 4), signature_alg)
}

pub fn serialize(builder: BytesBuilder, proof: SignatureProof) -> BytesBuilder {
  let builder =
    builder
    |> bytes_builder.append(<<make_type_and_flags_byte(proof)>>)
    |> public_key.serialize(proof.public_key)
    |> merkle_path.serialize(proof.merkle_path)
    |> signature.serialize(proof.signature)

  case proof.webauthn_fields {
    Some(fields) -> builder |> serialize_webauthn_fields(fields)
    None -> builder
  }
}

pub fn serialize_to_bits(proof: SignatureProof) -> BitArray {
  bytes_builder.new() |> serialize(proof) |> bytes_builder.to_bit_array()
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
) -> Result(#(WebauthnFields, BitArray), String) {
  use #(origin_json_str, rest) <- result.try(serde.deserialize_string(buf))
  use #(has_cross_origin_field, rest) <- result.try(serde.deserialize_bool(rest))
  use #(client_data_extra_json, rest) <- result.try(serde.deserialize_string(
    rest,
  ))
  use #(authenticator_data_suffix, rest) <- result.try(serde.deserialize_bytes(
    rest,
  ))

  Ok(#(
    WebauthnFields(
      origin_json_str,
      has_cross_origin_field,
      client_data_extra_json,
      authenticator_data_suffix,
    ),
    rest,
  ))
}

pub fn serialize_webauthn_fields(
  builder: BytesBuilder,
  fields: WebauthnFields,
) -> BytesBuilder {
  builder
  |> serde.serialize_string(fields.origin_json_str)
  |> serde.serialize_bool(fields.has_cross_origin_field)
  |> serde.serialize_string(fields.client_data_extra_json)
  |> serde.serialize_bytes(fields.authenticator_data_suffix)
}
