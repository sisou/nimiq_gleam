import gleam/int

pub type AccountType {
  Basic
  Vesting
  Htlc
  Staking
}

pub fn to_int(account_type: AccountType) -> Int {
  case account_type {
    Basic -> 0
    Vesting -> 1
    Htlc -> 2
    Staking -> 3
  }
}

pub fn from_int(value: Int) -> Result(AccountType, String) {
  case value {
    0 -> Ok(Basic)
    1 -> Ok(Vesting)
    2 -> Ok(Htlc)
    3 -> Ok(Staking)
    _ -> Error("Invalid account type: " <> int.to_string(value))
  }
}
