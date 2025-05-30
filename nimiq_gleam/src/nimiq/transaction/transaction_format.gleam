import gleam/int

pub type TransactionFormat {
  Basic
  Extended
}

pub fn to_int(format: TransactionFormat) -> Int {
  case format {
    Basic -> 0
    Extended -> 1
  }
}

pub fn from_int(value: Int) -> Result(TransactionFormat, String) {
  case value {
    0 -> Ok(Basic)
    1 -> Ok(Extended)
    _ -> Error("Invalid transaction format: " <> int.to_string(value))
  }
}
