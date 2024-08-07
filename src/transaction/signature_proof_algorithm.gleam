import gleam/int

pub type SignatureProofAlgorithm {
  Ed25519
  ES256
}

pub fn to_int(algorithm: SignatureProofAlgorithm) -> Int {
  case algorithm {
    Ed25519 -> 0
    ES256 -> 1
  }
}

pub fn from_int(value: Int) -> Result(SignatureProofAlgorithm, String) {
  case value {
    0 -> Ok(Ed25519)
    1 -> Ok(ES256)
    _ -> Error("Invalid signature proof algorithm: " <> int.to_string(value))
  }
}
