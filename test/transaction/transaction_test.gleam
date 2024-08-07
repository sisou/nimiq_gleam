import account/account.{BasicAccount}
import account/address
import coin.{Coin}
import gleam/bit_array
import gleam/option.{None}
import gleam/result
import gleeunit/should
import key/ed25519/public_key as ed25519_public_key
import key/ed25519/signature as ed25519_signature
import key/public_key.{EdDsaPublicKey}
import key/signature.{EdDsaSignature}
import merkle/merkle_path
import transaction/enums.{TestAlbatrossNetwork}
import transaction/signature_proof.{SignatureProof}
import transaction/transaction
import utils/misc

pub fn serialize_basic_test() {
  // Transaction data is from my explanation of Nimiq's transaction serialization at
  // https://gist.github.com/sisou/33ece69190cf38f884b1781ad9d5a106

  let assert Ok(sender) =
    "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1"
    |> address.from_user_friendly_address()

  let assert Ok(recipient) =
    "NQ34 248H 248H 248H 248H 248H 248H 248H 248H"
    |> address.from_user_friendly_address()

  let tx =
    transaction.new_basic(
      sender,
      recipient,
      Coin(100_000_000),
      Coin(138),
      100_000,
      TestAlbatrossNetwork,
      None,
    )

  transaction.serialize_content(tx)
  |> should.equal(<<
    0, 0, 104, 157, 174, 47, 119, 176, 72, 220, 192, 142, 20, 215, 49, 4, 234,
    20, 34, 43, 91, 225, 0, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    17, 17, 17, 17, 17, 17, 17, 0, 0, 0, 0, 0, 5, 245, 225, 0, 0, 0, 0, 0, 0, 0,
    0, 138, 0, 1, 134, 160, 5, 0, 0,
  >>)

  // Construct signature proof
  let assert Ok(public_key) =
    "3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29"
    |> ed25519_public_key.from_hex()
    |> result.map(EdDsaPublicKey)

  let assert Ok(signature) =
    "e97d14e5ab8b9e9b71f7d2952457810ff5c8c762ab92dded852eb915ed38e1f0c1332abced2a6dec66cc4cbfd025de9609712582872f94eabc67644b4d4f360e"
    |> ed25519_signature.from_hex()
    |> result.map(EdDsaSignature)

  let proof =
    SignatureProof(
      public_key:,
      merkle_path: merkle_path.empty(),
      signature:,
      webauthn_fields: None,
    )

  let tx = transaction.set_signature_proof(tx, proof)

  transaction.serialize_to_bits(tx)
  |> should.equal(
    Ok(<<
      0, 0, 59, 106, 39, 188, 206, 182, 164, 45, 98, 163, 168, 208, 42, 111, 13,
      115, 101, 50, 21, 119, 29, 226, 67, 166, 58, 192, 72, 161, 139, 89, 218,
      41, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 0, 0, 0, 0, 5, 245, 225, 0, 0, 0, 0, 0, 0, 0, 0, 138, 0, 1, 134,
      160, 5, 233, 125, 20, 229, 171, 139, 158, 155, 113, 247, 210, 149, 36, 87,
      129, 15, 245, 200, 199, 98, 171, 146, 221, 237, 133, 46, 185, 21, 237, 56,
      225, 240, 193, 51, 42, 188, 237, 42, 109, 236, 102, 204, 76, 191, 208, 37,
      222, 150, 9, 113, 37, 130, 135, 47, 148, 234, 188, 103, 100, 75, 77, 79,
      54, 14,
    >>),
  )
}

pub fn serialize_extended_test() {
  // Transaction data is from my explanation of Nimiq's transaction serialization at
  // https://gist.github.com/sisou/33ece69190cf38f884b1781ad9d5a106
  // with the added "Nimiq rocks!" message as recipient data

  let assert Ok(sender) =
    "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1"
    |> address.from_user_friendly_address()

  let assert Ok(recipient) =
    "NQ34 248H 248H 248H 248H 248H 248H 248H 248H"
    |> address.from_user_friendly_address()

  let tx =
    transaction.new_basic_with_data(
      sender,
      recipient,
      bit_array.from_string("Nimiq rocks!"),
      Coin(100_000_000),
      Coin(138),
      100_000,
      TestAlbatrossNetwork,
      None,
    )

  transaction.serialize_content(tx)
  |> should.equal(<<
    0, 12, 78, 105, 109, 105, 113, 32, 114, 111, 99, 107, 115, 33, 104, 157, 174,
    47, 119, 176, 72, 220, 192, 142, 20, 215, 49, 4, 234, 20, 34, 43, 91, 225, 0,
    17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    17, 0, 0, 0, 0, 0, 5, 245, 225, 0, 0, 0, 0, 0, 0, 0, 0, 138, 0, 1, 134, 160,
    5, 0, 0,
  >>)

  // Construct signature proof
  let assert Ok(public_key) =
    "3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29"
    |> ed25519_public_key.from_hex()
    |> result.map(EdDsaPublicKey)

  let assert Ok(signature) =
    "ae6c4c8bc8b3cbf2e96a1845e846bc65e5e9d60d9989746cb14e7f0b195d77ec48eaaf592dc3720ba2d095fa7d15808c168b687cb0092e16f332f313ab45c609"
    |> ed25519_signature.from_hex()
    |> result.map(EdDsaSignature)

  let proof =
    SignatureProof(
      public_key:,
      merkle_path: merkle_path.empty(),
      signature:,
      webauthn_fields: None,
    )

  let tx = transaction.set_signature_proof(tx, proof)

  transaction.serialize_to_bits(tx)
  |> should.equal(
    Ok(<<
      1, 104, 157, 174, 47, 119, 176, 72, 220, 192, 142, 20, 215, 49, 4, 234, 20,
      34, 43, 91, 225, 0, 0, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 0, 12, 78, 105, 109, 105, 113, 32, 114, 111,
      99, 107, 115, 33, 0, 0, 0, 0, 5, 245, 225, 0, 0, 0, 0, 0, 0, 0, 0, 138, 0,
      1, 134, 160, 5, 0, 98, 0, 59, 106, 39, 188, 206, 182, 164, 45, 98, 163,
      168, 208, 42, 111, 13, 115, 101, 50, 21, 119, 29, 226, 67, 166, 58, 192,
      72, 161, 139, 89, 218, 41, 0, 174, 108, 76, 139, 200, 179, 203, 242, 233,
      106, 24, 69, 232, 70, 188, 101, 229, 233, 214, 13, 153, 137, 116, 108, 177,
      78, 127, 11, 25, 93, 119, 236, 72, 234, 175, 89, 45, 195, 114, 11, 162,
      208, 149, 250, 125, 21, 128, 140, 22, 139, 104, 124, 176, 9, 46, 22, 243,
      50, 243, 19, 171, 69, 198, 9,
    >>),
  )
}

pub fn deserialize_basic_test() {
  let assert Ok(tx) =
    transaction.deserialize_all(<<
      0, 0, 59, 106, 39, 188, 206, 182, 164, 45, 98, 163, 168, 208, 42, 111, 13,
      115, 101, 50, 21, 119, 29, 226, 67, 166, 58, 192, 72, 161, 139, 89, 218,
      41, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 0, 0, 0, 0, 5, 245, 225, 0, 0, 0, 0, 0, 0, 0, 0, 138, 0, 1, 134,
      160, 5, 233, 125, 20, 229, 171, 139, 158, 155, 113, 247, 210, 149, 36, 87,
      129, 15, 245, 200, 199, 98, 171, 146, 221, 237, 133, 46, 185, 21, 237, 56,
      225, 240, 193, 51, 42, 188, 237, 42, 109, 236, 102, 204, 76, 191, 208, 37,
      222, 150, 9, 113, 37, 130, 135, 47, 148, 234, 188, 103, 100, 75, 77, 79,
      54, 14,
    >>)

  let assert "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1" =
    tx.sender
    |> address.to_user_friendly_address()
  let assert BasicAccount = tx.sender_type
  let assert <<>> = tx.sender_data
  let assert "NQ34 248H 248H 248H 248H 248H 248H 248H 248H" =
    tx.recipient
    |> address.to_user_friendly_address()
  let assert BasicAccount = tx.recipient_type
  let assert <<>> = tx.recipient_data
  let assert Coin(100_000_000) = tx.value
  let assert Coin(138) = tx.fee
  let assert 100_000 = tx.validity_start_height
  let assert TestAlbatrossNetwork = tx.network_id
  let assert "003b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da2900e97d14e5ab8b9e9b71f7d2952457810ff5c8c762ab92dded852eb915ed38e1f0c1332abced2a6dec66cc4cbfd025de9609712582872f94eabc67644b4d4f360e" =
    tx.proof |> misc.to_hex()
}

pub fn deserialize_extended_test() {
  let assert Ok(tx) =
    transaction.deserialize_all(<<
      1, 104, 157, 174, 47, 119, 176, 72, 220, 192, 142, 20, 215, 49, 4, 234, 20,
      34, 43, 91, 225, 0, 0, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
      17, 17, 17, 17, 17, 17, 17, 0, 12, 78, 105, 109, 105, 113, 32, 114, 111,
      99, 107, 115, 33, 0, 0, 0, 0, 5, 245, 225, 0, 0, 0, 0, 0, 0, 0, 0, 138, 0,
      1, 134, 160, 5, 0, 98, 0, 59, 106, 39, 188, 206, 182, 164, 45, 98, 163,
      168, 208, 42, 111, 13, 115, 101, 50, 21, 119, 29, 226, 67, 166, 58, 192,
      72, 161, 139, 89, 218, 41, 0, 174, 108, 76, 139, 200, 179, 203, 242, 233,
      106, 24, 69, 232, 70, 188, 101, 229, 233, 214, 13, 153, 137, 116, 108, 177,
      78, 127, 11, 25, 93, 119, 236, 72, 234, 175, 89, 45, 195, 114, 11, 162,
      208, 149, 250, 125, 21, 128, 140, 22, 139, 104, 124, 176, 9, 46, 22, 243,
      50, 243, 19, 171, 69, 198, 9,
    >>)

  let assert "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1" =
    tx.sender
    |> address.to_user_friendly_address()
  let assert BasicAccount = tx.sender_type
  let assert <<>> = tx.sender_data
  let assert "NQ34 248H 248H 248H 248H 248H 248H 248H 248H" =
    tx.recipient
    |> address.to_user_friendly_address()
  let assert BasicAccount = tx.recipient_type
  let assert Ok("Nimiq rocks!") = tx.recipient_data |> bit_array.to_string()
  let assert Coin(100_000_000) = tx.value
  let assert Coin(138) = tx.fee
  let assert 100_000 = tx.validity_start_height
  let assert TestAlbatrossNetwork = tx.network_id
  let assert "003b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da2900ae6c4c8bc8b3cbf2e96a1845e846bc65e5e9d60d9989746cb14e7f0b195d77ec48eaaf592dc3720ba2d095fa7d15808c168b687cb0092e16f332f313ab45c609" =
    tx.proof |> misc.to_hex()
}
