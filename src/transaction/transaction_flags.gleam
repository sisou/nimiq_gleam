import gleam/int
import gleam/option.{type Option, None, Some}

pub type TransactionFlags {
  ContractCreation
  Signaling
}

pub fn to_int(flags: Option(TransactionFlags)) -> Int {
  case flags {
    None -> 0b00000000
    Some(ContractCreation) -> 0b00000001
    Some(Signaling) -> 0b00000010
  }
}

pub fn from_int(value: Int) -> Result(Option(TransactionFlags), String) {
  case value {
    0b00000000 -> Ok(None)
    0b00000001 -> Ok(Some(ContractCreation))
    0b00000010 -> Ok(Some(Signaling))
    _ -> Error("Invalid transaction flags: " <> int.to_string(value))
  }
}
