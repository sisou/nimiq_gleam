pub type AccountType {
  BasicAccount
  VestingContract
  HashedTimeLockedContract
  StakingContract
}

pub fn from_account_type(account_type: AccountType) -> Int {
  case account_type {
    BasicAccount -> 0
    VestingContract -> 1
    HashedTimeLockedContract -> 2
    StakingContract -> 3
  }
}

pub fn to_account_type(account_type: Int) -> Result(AccountType, String) {
  case account_type {
    0 -> Ok(BasicAccount)
    1 -> Ok(VestingContract)
    2 -> Ok(HashedTimeLockedContract)
    3 -> Ok(StakingContract)
    _ -> Error("Invalid account type")
  }
}
