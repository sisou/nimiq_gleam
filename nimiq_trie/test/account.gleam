import gleam/bytes_tree.{type BytesTree}
import gleam/result

import nimiq/utils/serde

pub type Account {
  Basic(balance: Int)
  // Vesting(balance: Int)
  // Htlc(balance: Int)
  // Staking(balance: Int)
}

pub fn serialize(buf: BytesTree, account: Account) -> BytesTree {
  case account {
    Basic(balance) -> {
      buf
      |> serde.serialize_u8(0)
      |> serde.serialize_u64(balance)
    }
    // Vesting(_balance) ->
    //   todo as "Serialization of Vesting account is not implemented"
    // Htlc(_balance) -> todo as "Serialization of HTLC account is not implemented"
    // Staking(_balance) ->
    //   todo as "Serialization of Staking account is not implemented"
  }
}

pub fn serialize_to_vec(account: Account) -> BitArray {
  bytes_tree.new() |> serialize(account) |> bytes_tree.to_bit_array()
}

pub fn deserialize(buf: BitArray) -> Result(#(Account, BitArray), String) {
  use #(account_type, rest) <- result.try(serde.deserialize_u8(buf))
  case account_type {
    0 -> {
      use #(balance, rest) <- result.try(serde.deserialize_u64(rest))
      Ok(#(Basic(balance), rest))
    }
    // 1 -> todo as "Deserialization of Vesting account is not implemented"
    // 2 -> todo as "Deserialization of HTLC account is not implemented"
    // 3 -> todo as "Deserialization of Staking account is not implemented"
    _ -> Error("Invalid account type")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(Account, String) {
  case deserialize(buf) {
    Ok(#(account, <<>>)) -> Ok(account)
    Ok(_) -> Error("Invalid account: trailing bytes")
    Error(err) -> Error(err)
  }
}
