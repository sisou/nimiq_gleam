import gleam/bytes_tree

pub type Account {
  Basic(balance: Int)
  // Vesting(balance: Int)
  // Htlc(balance: Int)
  // Staking(balance: Int)
}

pub fn serialize_to_vec(account: Account) -> BitArray {
  case account {
    Basic(balance) -> {
      bytes_tree.new()
      |> bytes_tree.append(<<0>>)
      |> bytes_tree.append(<<balance:64>>)
      |> bytes_tree.to_bit_array()
    }
    // Vesting(_balance) ->
    //   todo as "Serialization of Vesting account is not implemented"
    // Htlc(_balance) -> todo as "Serialization of HTLC account is not implemented"
    // Staking(_balance) ->
    //   todo as "Serialization of Staking account is not implemented"
  }
}
