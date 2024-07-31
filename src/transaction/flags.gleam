import gleam/option.{type Option, None, Some}

pub type SignatureProofFlags {
  WebauthnFieldsFlag
}

pub fn from_signature_proof_flags(flags: Option(SignatureProofFlags)) -> Int {
  case flags {
    None -> 0b0000
    Some(WebauthnFieldsFlag) -> 0b0001
  }
}

pub fn to_signature_proof_flags(
  flags: Int,
) -> Result(Option(SignatureProofFlags), String) {
  case flags {
    0b0000 -> Ok(None)
    0b0001 -> Ok(Some(WebauthnFieldsFlag))
    _ -> Error("Invalid signature proof flags")
  }
}

pub type TransactionFlags {
  ContractCreationFlag
  SignalingFlag
}

pub fn from_transaction_flags(flags: Option(TransactionFlags)) -> Int {
  case flags {
    None -> 0b00000000
    Some(ContractCreationFlag) -> 0b00000001
    Some(SignalingFlag) -> 0b00000010
  }
}

pub fn to_transaction_flags(
  flags: Int,
) -> Result(Option(TransactionFlags), String) {
  case flags {
    0b00000000 -> Ok(None)
    0b00000001 -> Ok(Some(ContractCreationFlag))
    0b00000010 -> Ok(Some(SignalingFlag))
    _ -> Error("Invalid transaction flags")
  }
}
