import account/account_type.{type AccountType}
import account/address.{type Address}
import coin.{type Coin, Coin}
import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import key/public_key
import key/signature
import transaction/network_id.{type NetworkId}
import transaction/signature_proof.{type SignatureProof}
import transaction/signature_proof_flags
import transaction/transaction_flags.{type TransactionFlags}
import transaction/transaction_format.{type TransactionFormat}
import utils/misc
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
    account_type.Basic,
    <<>>,
    recipient,
    account_type.Basic,
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
    account_type.Basic,
    <<>>,
    recipient,
    account_type.Basic,
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
    transaction_format.Basic -> {
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
        Some(signature_proof_flags.WebauthnFields) ->
          signature_proof.deserialize_webauthn_fields(rest)
          |> result.map(fn(tuple) {
            let #(fields, rest) = tuple
            #(Some(fields), rest)
          })
        None -> Ok(#(None, rest))
      })

      use network_id <- result.try(network_id.from_int(network_id))

      let proof =
        case webauthn_fields {
          Some(fields) ->
            signature_proof.single_sig_webauthn(public_key, signature, fields)
          None -> signature_proof.single_sig(public_key, signature)
        }
        |> signature_proof.serialize_to_bits()

      let tx =
        Transaction(
          public_key.to_address(public_key),
          account_type.Basic,
          <<>>,
          recipient,
          account_type.Basic,
          <<>>,
          Coin(value),
          Coin(fee),
          validity_start_height,
          network_id,
          None,
          proof,
        )

      Ok(#(tx, rest))
    }
    transaction_format.Extended -> {
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

      use network_id <- result.try(network_id.from_int(network_id))
      use sender_type <- result.try(account_type.from_int(sender_type))
      use recipient_type <- result.try(account_type.from_int(recipient_type))
      use flags <- result.try(transaction_flags.from_int(flags))

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
      case transaction_format.from_int(byte) {
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

pub fn set_signature_proof(
  tx: Transaction,
  proof: SignatureProof,
) -> Transaction {
  set_proof(tx, signature_proof.serialize_to_bits(proof))
}

pub fn format(tx: Transaction) -> TransactionFormat {
  case
    tx.sender_type == account_type.Basic
    && tx.recipient_type == account_type.Basic
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
    True -> transaction_format.Basic
    False -> transaction_format.Extended
  }
}

pub fn serialize_content(tx: Transaction) -> BitArray {
  bytes_builder.new()
  // Recipient data length
  |> bytes_builder.append(<<bit_array.byte_size(tx.recipient_data):16>>)
  // Recipient data
  |> bytes_builder.append(tx.recipient_data)
  // Sender address
  |> address.serialize(tx.sender)
  // Sender account type
  |> bytes_builder.append(<<account_type.to_int(tx.sender_type):8>>)
  // Recipient address
  |> address.serialize(tx.recipient)
  // Recipient account type
  |> bytes_builder.append(<<account_type.to_int(tx.recipient_type):8>>)
  // Value
  |> bytes_builder.append(<<tx.value.luna:64>>)
  // Fee
  |> bytes_builder.append(<<tx.fee.luna:64>>)
  // Validity start height
  |> bytes_builder.append(<<tx.validity_start_height:32>>)
  // Network ID
  |> bytes_builder.append(<<network_id.to_int(tx.network_id):8>>)
  // Flags
  |> bytes_builder.append(<<transaction_flags.to_int(tx.flags):8>>)
  // Sender data
  |> serde.serialize_bytes(tx.sender_data)
  // Convert to bit array
  |> bytes_builder.to_bit_array()
}

pub fn serialize(
  builder: BytesBuilder,
  tx: Transaction,
) -> Result(BytesBuilder, String) {
  let format = format(tx)

  let builder =
    builder
    |> bytes_builder.append(<<transaction_format.to_int(format):8>>)

  case format {
    transaction_format.Basic -> {
      use signature_proof <- result.try(
        tx.proof |> signature_proof.deserialize_all(),
      )

      let builder =
        builder
        |> bytes_builder.append(<<
          signature_proof.make_type_and_flags_byte(signature_proof):8,
        >>)
        // Sender public key
        |> public_key.serialize(signature_proof.public_key)
        // Recipient address
        |> address.serialize(tx.recipient)
        // Value
        |> bytes_builder.append(<<tx.value.luna:64>>)
        // Fee
        |> bytes_builder.append(<<tx.fee.luna:64>>)
        // Validity start height
        |> bytes_builder.append(<<tx.validity_start_height:32>>)
        // Network ID
        |> bytes_builder.append(<<network_id.to_int(tx.network_id):8>>)
        // Signature
        |> signature.serialize(signature_proof.signature)

      case signature_proof.webauthn_fields {
        Some(fields) -> {
          builder |> signature_proof.serialize_webauthn_fields(fields)
        }
        None -> builder
      }
      |> Ok()
    }
    transaction_format.Extended -> {
      builder
      |> address.serialize(tx.sender)
      |> bytes_builder.append(<<account_type.to_int(tx.sender_type):8>>)
      |> serde.serialize_bytes(tx.sender_data)
      |> address.serialize(tx.recipient)
      |> bytes_builder.append(<<account_type.to_int(tx.recipient_type):8>>)
      |> serde.serialize_bytes(tx.recipient_data)
      |> bytes_builder.append(<<tx.value.luna:64>>)
      |> bytes_builder.append(<<tx.fee.luna:64>>)
      |> bytes_builder.append(<<tx.validity_start_height:32>>)
      |> bytes_builder.append(<<network_id.to_int(tx.network_id):8>>)
      |> bytes_builder.append(<<transaction_flags.to_int(tx.flags):8>>)
      |> serde.serialize_bytes(tx.proof)
      |> Ok()
    }
  }
}

pub fn serialize_to_bits(tx: Transaction) -> Result(BitArray, String) {
  bytes_builder.new() |> serialize(tx) |> result.map(bytes_builder.to_bit_array)
}

pub fn to_hex(tx: Transaction) -> Result(String, String) {
  use bytes <- result.try(tx |> serialize_to_bits())
  Ok(bytes |> misc.to_hex())
}
