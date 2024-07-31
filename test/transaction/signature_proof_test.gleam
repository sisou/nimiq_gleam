import account/address
import coin.{Coin}
import gleam/bit_array
import gleam/option.{None}
import gleam/string
import gleeunit/should
import key/ed25519/private_key as ed25519_private_key
import key/ed25519/public_key as ed25519_public_key
import key/ed25519/signature as ed25519_signature
import key/public_key.{EdDsaPublicKey}
import key/signature.{EdDsaSignature}
import transaction/enums.{TestAlbatrossNetwork}
import transaction/signature_proof
import transaction/transaction

pub fn basic_signature_proof_test() {
  // Transaction data is from my explanation of Nimiq's transaction serialization at
  // https://gist.github.com/sisou/33ece69190cf38f884b1781ad9d5a106

  let tx =
    transaction.new_basic(
      case
        address.from_user_friendly_address(
          "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1",
        )
      {
        Ok(addr) -> addr
        Error(_) -> panic as "Invalid sender address"
      },
      case
        address.from_user_friendly_address(
          "NQ34 248H 248H 248H 248H 248H 248H 248H 248H",
        )
      {
        Ok(addr) -> addr
        Error(_) -> panic as "Invalid recipient address"
      },
      Coin(100_000_000),
      Coin(138),
      100_000,
      TestAlbatrossNetwork,
      None,
    )

  // Construct signature proof
  let private_key = case
    ed25519_private_key.from_hex(
      "0000000000000000000000000000000000000000000000000000000000000000",
    )
  {
    Ok(pk) -> pk
    Error(_) -> panic as "Invalid private key"
  }
  let public_key = ed25519_public_key.derive_key(private_key)
  let signature =
    ed25519_signature.create(
      private_key,
      public_key,
      transaction.serialize_content(tx),
    )

  signature_proof.single_sig(
    EdDsaPublicKey(public_key),
    EdDsaSignature(signature),
  )
  |> signature_proof.serialize()
  |> bit_array.base16_encode()
  |> string.lowercase()
  |> should.equal(
    "00"
    <> "3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29"
    <> "00"
    <> "e97d14e5ab8b9e9b71f7d2952457810ff5c8c762ab92dded852eb915ed38e1f0c1332abced2a6dec66cc4cbfd025de9609712582872f94eabc67644b4d4f360e",
  )
}
