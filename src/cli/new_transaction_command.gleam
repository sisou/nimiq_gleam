import account/address
import coin.{Coin}
import gleam/bit_array
import gleam/int
import gleam/io
import gleam/option.{None}
import gleam/result
import gleam/string
import glint
import glint/constraint
import key/ed25519/private_key as ed25519_private_key
import key/ed25519/public_key as ed25519_public_key
import key/ed25519/signature as ed25519_signature
import key/public_key.{EdDsaPublicKey}
import key/signature.{EdDsaSignature}
import snag
import transaction/network_id
import transaction/signature_proof
import transaction/transaction
import transaction/transaction_builder
import utils/misc

fn fee_flag() -> glint.Flag(Int) {
  glint.int_flag("fee")
  |> glint.flag_default(0)
  |> glint.flag_help("Set the transaction's fee in luna. Default is 0.")
}

fn msg_flag() -> glint.Flag(String) {
  glint.string_flag("msg")
  |> glint.flag_help("Add a message to the transaction, maximum 64 bytes.")
  |> glint.flag_constraint(fn(msg: String) -> Result(String, snag.Snag) {
    case string.byte_size(msg) <= 64 {
      True -> Ok(msg)
      False -> Error(snag.new("msg must not be longer than 64 bytes"))
    }
  })
}

fn network_flag() -> glint.Flag(Int) {
  glint.int_flag("network")
  // Albatross Testnet
  |> glint.flag_default(5)
  |> glint.flag_constraint([5, 24] |> constraint.one_of())
  |> glint.flag_help(
    "Set the network ID. Albatross Testnet => 5, Albatross Mainnet => 24. Default is 5.",
  )
}

fn private_key_flag() -> glint.Flag(String) {
  glint.string_flag("sign-with")
  |> glint.flag_help("Set the private key to sign the transaction with.")
  |> glint.flag_constraint(fn(key: String) -> Result(String, snag.Snag) {
    case bit_array.base16_decode(key) {
      Ok(_) -> Ok(key)
      Error(_) -> Error(snag.new("private key must be 32 bytes in hex format"))
    }
  })
}

pub fn run() -> glint.Command(Nil) {
  use <- glint.command_help("Creates Nimiq transactions")

  use sender <- glint.named_arg("SENDER")
  use recipient <- glint.named_arg("RECIPIENT")
  use value <- glint.named_arg("VALUE_LUNA")
  use fee <- glint.flag(fee_flag())
  use msg <- glint.flag(msg_flag())
  use validity_start_height <- glint.named_arg("VALIDITY_START_HEIGHT")
  use network_id <- glint.flag(network_flag())
  use private_key <- glint.flag(private_key_flag())

  use named, _, flags <- glint.command()

  let assert Ok(sender) = sender(named) |> address.from_string()
  let assert Ok(recipient) = recipient(named) |> address.from_string()
  let assert Ok(value) = value(named) |> int.parse() |> result.map(Coin)
  let assert Ok(fee) = fee(flags) |> result.map(Coin)
  let data =
    msg(flags) |> result.map(bit_array.from_string) |> result.unwrap(<<>>)
  let assert Ok(validity_start_height) =
    validity_start_height(named) |> int.parse()
  let assert Ok(network_id) =
    network_id(flags)
    |> result.map(fn(num) { network_id.from_int(num) |> misc.unwrap() })

  // Business logic of the command
  let tx =
    transaction_builder.new_basic_with_data(
      sender,
      recipient,
      data,
      value,
      fee,
      validity_start_height,
      network_id,
      None,
    )

  case private_key(flags) {
    Error(_) -> tx
    Ok(private_key) -> {
      let assert Ok(private_key) = private_key |> ed25519_private_key.from_hex()

      let public_key = ed25519_public_key.derive_key(private_key)

      let signature =
        ed25519_signature.create(
          private_key,
          public_key,
          transaction.serialize_content(tx),
        )

      let proof =
        signature_proof.single_sig(
          EdDsaPublicKey(public_key),
          EdDsaSignature(signature),
        )

      transaction.set_signature_proof(tx, proof)
    }
  }
  |> transaction.to_hex()
  |> misc.unwrap()
  |> io.println
}
