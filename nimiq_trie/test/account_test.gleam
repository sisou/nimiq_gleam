import gleam/bit_array
import gleam/string

import account

pub fn serialize_account_test() {
  assert account.Basic(balance: 100_000)
    |> account.serialize_to_vec()
    |> bit_array.base16_encode()
    |> string.lowercase()
    == "0000000000000186a0"
}
