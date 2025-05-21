import gleam/bytes_tree
import utils/serde

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
      |> serde.serialize_int(0, 8)
      |> serde.serialize_int(balance, 64)
      |> bytes_tree.to_bit_array()
    }
    // Vesting(_balance) ->
    //   todo as "Serialization of Vesting account is not implemented"
    // Htlc(_balance) -> todo as "Serialization of HTLC account is not implemented"
    // Staking(_balance) ->
    //   todo as "Serialization of Staking account is not implemented"
  }
}
