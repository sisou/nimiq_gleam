import bindings/bls as native
import gleam/bytes_builder.{type BytesBuilder}

pub type CompressedSignature {
  CompressedSignature(sig: native.Signature)
}

pub fn serialize(
  builder: BytesBuilder,
  signature: CompressedSignature,
) -> BytesBuilder {
  builder |> bytes_builder.append(native.signature_to_bytes(signature.sig))
}

pub fn serialize_to_bits(signature: CompressedSignature) -> BitArray {
  native.signature_to_bytes(signature.sig)
}
