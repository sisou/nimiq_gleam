import address
import gleam/result
import gleeunit/should
import transaction

pub fn basic_serialize_content_test() {
  // Transaction data is from my explanation of Nimiq's transaction serialization at
  // https://gist.github.com/sisou/33ece69190cf38f884b1781ad9d5a106

  let tx =
    transaction.new_basic(
      address.from_user_friendly_address(
        "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1",
      )
        |> result.unwrap(address.zero()),
      address.from_user_friendly_address(
        "NQ34 248H 248H 248H 248H 248H 248H 248H 248H",
      )
        |> result.unwrap(address.zero()),
      transaction.Coin(100_000_000),
      transaction.Coin(138),
      100_000,
      transaction.TestAlbatrossNetwork,
    )

  should.equal(transaction.serialize_content(tx), <<
    0, 0, 104, 157, 174, 47, 119, 176, 72, 220, 192, 142, 20, 215, 49, 4, 234,
    20, 34, 43, 91, 225, 0, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    17, 17, 17, 17, 17, 17, 17, 0, 0, 0, 0, 0, 5, 245, 225, 0, 0, 0, 0, 0, 0, 0,
    0, 138, 0, 1, 134, 160, 5, 0, 0,
  >>)
}
