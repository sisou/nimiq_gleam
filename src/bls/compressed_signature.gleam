import bindings/bls as native
import gleam/bytes_tree.{type BytesTree}

pub type CompressedSignature {
  CompressedSignature(sig: native.Signature)
}

pub fn serialize(
  builder: BytesTree,
  signature: CompressedSignature,
) -> BytesTree {
  builder |> bytes_tree.append(native.signature_to_bytes(signature.sig))
}

pub fn serialize_to_bits(signature: CompressedSignature) -> BitArray {
  native.signature_to_bytes(signature.sig)
}
