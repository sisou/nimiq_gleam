import gleam/int
import gleam/option.{type Option, None, Some}

pub type SignatureProofFlags {
  WebauthnFields
}

pub fn to_int(flags: Option(SignatureProofFlags)) -> Int {
  case flags {
    None -> 0b0000
    Some(WebauthnFields) -> 0b0001
  }
}

pub fn from_int(value: Int) -> Result(Option(SignatureProofFlags), String) {
  case value {
    0b0000 -> Ok(None)
    0b0001 -> Ok(Some(WebauthnFields))
    _ -> Error("Invalid signature proof flags: " <> int.to_string(value))
  }
}
