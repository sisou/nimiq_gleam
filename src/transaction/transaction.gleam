import account/account.{type AccountType, BasicAccount}
import account/address.{type Address}
import coin.{type Coin, Coin}
import gleam/bit_array
import gleam/bytes_builder
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import key/public_key
import key/signature
import transaction/enums.{
  type NetworkId, type TransactionFormat, BasicFormat, ExtendedFormat,
}
import transaction/flags.{type TransactionFlags, WebauthnFieldsFlag}
import transaction/signature_proof
import utils/serde

pub type Transaction {
  Transaction(
    sender: Address,
    sender_type: AccountType,
    sender_data: BitArray,
    recipient: Address,
    recipient_type: AccountType,
    recipient_data: BitArray,
    value: Coin,
    fee: Coin,
    validity_start_height: Int,
    network_id: NetworkId,
    flags: Option(TransactionFlags),
    proof: BitArray,
  )
}

pub fn new_basic(
  sender: Address,
  recipient: Address,
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
  proof: Option(BitArray),
) -> Transaction {
  Transaction(
    sender,
    BasicAccount,
    <<>>,
    recipient,
    BasicAccount,
    <<>>,
    value,
    fee,
    validity_start_height,
    network_id,
    None,
    option.unwrap(proof, <<>>),
  )
}

pub fn new_basic_with_data(
  sender: Address,
  recipient: Address,
  data: BitArray,
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
  proof: Option(BitArray),
) -> Transaction {
  Transaction(
    sender,
    BasicAccount,
    <<>>,
    recipient,
    BasicAccount,
    data,
    value,
    fee,
    validity_start_height,
    network_id,
    None,
    option.unwrap(proof, <<>>),
  )
}

pub fn deserialize(buf: BitArray) -> Result(#(Transaction, BitArray), String) {
  use #(format, rest) <- result.try(deserialize_format(buf))

  case format {
    BasicFormat -> {
      use #(#(signature_alg, flags), rest) <- result.try(
        signature_proof.deserialize_type_and_flags_byte(rest),
      )
      use #(public_key, rest) <- result.try(public_key.deserialize_typed(
        rest,
        signature_alg,
      ))
      use #(recipient, rest) <- result.try(address.deserialize(rest))
      use #(value, rest) <- result.try(serde.deserialize_int(rest, 64))
      use #(fee, rest) <- result.try(serde.deserialize_int(rest, 64))
      use #(validity_start_height, rest) <- result.try(serde.deserialize_int(
        rest,
        32,
      ))
      use #(network_id, rest) <- result.try(serde.deserialize_int(rest, 8))
      use #(signature, rest) <- result.try(signature.deserialize_typed(
        rest,
        signature_alg,
      ))
      use #(webauthn_fields, rest) <- result.try(case flags {
        Some(WebauthnFieldsFlag) ->
          signature_proof.deserialize_webauthn_fields(rest)
          |> result.map(fn(tuple) {
            let #(fields, rest) = tuple
            #(Some(fields), rest)
          })
        None -> Ok(#(None, rest))
      })

      use network_id <- result.try(enums.to_network_id(network_id))

      let proof = case webauthn_fields {
        Some(fields) ->
          signature_proof.single_sig_webauthn(public_key, signature, fields)
        None -> signature_proof.single_sig(public_key, signature)
      }

      let tx =
        Transaction(
          public_key.to_address(public_key),
          BasicAccount,
          <<>>,
          recipient,
          BasicAccount,
          <<>>,
          Coin(value),
          Coin(fee),
          validity_start_height,
          network_id,
          None,
          proof |> signature_proof.serialize(),
        )

      Ok(#(tx, rest))
    }
    ExtendedFormat -> {
      use #(sender, rest) <- result.try(address.deserialize(rest))
      use #(sender_type, rest) <- result.try(serde.deserialize_int(rest, 8))
      use #(sender_data, rest) <- result.try(serde.deserialize_bytes(rest))
      use #(recipient, rest) <- result.try(address.deserialize(rest))
      use #(recipient_type, rest) <- result.try(serde.deserialize_int(rest, 8))
      use #(recipient_data, rest) <- result.try(serde.deserialize_bytes(rest))
      use #(value, rest) <- result.try(serde.deserialize_int(rest, 64))
      use #(fee, rest) <- result.try(serde.deserialize_int(rest, 64))
      use #(validity_start_height, rest) <- result.try(serde.deserialize_int(
        rest,
        32,
      ))
      use #(network_id, rest) <- result.try(serde.deserialize_int(rest, 8))
      use #(flags, rest) <- result.try(serde.deserialize_int(rest, 8))
      use #(proof, rest) <- result.try(serde.deserialize_bytes(rest))

      use network_id <- result.try(enums.to_network_id(network_id))
      use sender_type <- result.try(account.to_account_type(sender_type))
      use recipient_type <- result.try(account.to_account_type(recipient_type))
      use flags <- result.try(flags.to_transaction_flags(flags))

      let tx =
        Transaction(
          sender,
          sender_type,
          sender_data,
          recipient,
          recipient_type,
          recipient_data,
          Coin(value),
          Coin(fee),
          validity_start_height,
          network_id,
          flags,
          proof,
        )

      Ok(#(tx, rest))
    }
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(Transaction, String) {
  case deserialize(buf) {
    Ok(#(tx, <<>>)) -> Ok(tx)
    Ok(_) -> Error("Invalid transaction: trailing bytes")
    Error(err) -> Error(err)
  }
}

fn deserialize_format(
  buf: BitArray,
) -> Result(#(TransactionFormat, BitArray), String) {
  case buf {
    <<byte:8, rest:bits>> -> {
      case enums.to_transaction_format(byte) {
        Ok(format) -> Ok(#(format, rest))
        Error(err) -> Error(err)
      }
    }
    _ -> Error("Invalid transaction format: out of data")
  }
}

pub fn from_hex(hex: String) -> Result(Transaction, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid transaction: not a valid hex encoding")
  }
}

pub fn set_proof(tx: Transaction, proof: BitArray) -> Transaction {
  Transaction(..tx, proof: proof)
}

pub fn format(tx: Transaction) -> TransactionFormat {
  case
    tx.sender_type == BasicAccount
    && tx.recipient_type == BasicAccount
    && tx.recipient_data == <<>>
    && tx.flags == None
    && case signature_proof.deserialize_all(tx.proof) {
      Ok(signature_proof) -> {
        public_key.to_address(signature_proof.public_key) == tx.sender
        && list.is_empty(signature_proof.merkle_path.nodes)
      }
      Error(_) -> False
    }
  {
    True -> BasicFormat
    False -> ExtendedFormat
  }
}

pub fn serialize_content(tx: Transaction) -> BitArray {
  bytes_builder.new()
  // Recipient data length
  |> bytes_builder.append(<<bit_array.byte_size(tx.recipient_data):16>>)
  // Recipient data
  |> bytes_builder.append(tx.recipient_data)
  // Sender address
  |> bytes_builder.append(address.serialize(tx.sender))
  // Sender account type
  |> bytes_builder.append(<<account.from_account_type(tx.sender_type):8>>)
  // Recipient address
  |> bytes_builder.append(address.serialize(tx.recipient))
  // Recipient account type
  |> bytes_builder.append(<<account.from_account_type(tx.recipient_type):8>>)
  // Value
  |> bytes_builder.append(<<tx.value.luna:64>>)
  // Fee
  |> bytes_builder.append(<<tx.fee.luna:64>>)
  // Validity start height
  |> bytes_builder.append(<<tx.validity_start_height:32>>)
  // Network ID
  |> bytes_builder.append(<<enums.from_network_id(tx.network_id):8>>)
  // Flags
  |> bytes_builder.append(<<flags.from_transaction_flags(tx.flags):8>>)
  // Sender data
  |> serde.serialize_bytes(tx.sender_data)
  // Convert to bit array
  |> bytes_builder.to_bit_array()
}

pub fn serialize(tx: Transaction) -> Result(BitArray, String) {
  let format = format(tx)

  let buf =
    bytes_builder.new()
    |> bytes_builder.append(<<enums.from_transaction_format(format):8>>)

  case format {
    BasicFormat -> {
      use signature_proof <- result.try(
        tx.proof |> signature_proof.deserialize_all(),
      )

      buf
      |> bytes_builder.append(<<
        signature_proof.make_type_and_flags_byte(signature_proof):8,
      >>)
      // Sender public key
      |> bytes_builder.append(public_key.serialize(signature_proof.public_key))
      // Recipient address
      |> bytes_builder.append(address.serialize(tx.recipient))
      // Value
      |> bytes_builder.append(<<tx.value.luna:64>>)
      // Fee
      |> bytes_builder.append(<<tx.fee.luna:64>>)
      // Validity start height
      |> bytes_builder.append(<<tx.validity_start_height:32>>)
      // Network ID
      |> bytes_builder.append(<<enums.from_network_id(tx.network_id):8>>)
      // Signature
      |> bytes_builder.append(signature.serialize(signature_proof.signature))
      |> bytes_builder.append(case signature_proof.webauthn_fields {
        Some(fields) -> {
          signature_proof.serialize_webauthn_fields(fields)
        }
        None -> <<>>
      })
      // Convert to bit array
      |> bytes_builder.to_bit_array()
      |> Ok()
    }
    ExtendedFormat -> {
      buf
      |> bytes_builder.append(address.serialize(tx.sender))
      |> bytes_builder.append(<<account.from_account_type(tx.sender_type):8>>)
      |> serde.serialize_bytes(tx.sender_data)
      |> bytes_builder.append(address.serialize(tx.recipient))
      |> bytes_builder.append(<<account.from_account_type(tx.recipient_type):8>>)
      |> serde.serialize_bytes(tx.recipient_data)
      |> bytes_builder.append(<<tx.value.luna:64>>)
      |> bytes_builder.append(<<tx.fee.luna:64>>)
      |> bytes_builder.append(<<tx.validity_start_height:32>>)
      |> bytes_builder.append(<<enums.from_network_id(tx.network_id):8>>)
      |> bytes_builder.append(<<flags.from_transaction_flags(tx.flags):8>>)
      |> serde.serialize_bytes(tx.proof)
      |> bytes_builder.to_bit_array()
      |> Ok()
    }
  }
}

pub fn to_hex(tx: Transaction) -> Result(String, String) {
  use bytes <- result.try(tx |> serialize())
  bytes |> bit_array.base16_encode() |> string.lowercase() |> Ok()
}
