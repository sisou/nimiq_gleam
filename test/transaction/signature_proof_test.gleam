import account/address
import coin.{Coin}
import gleam/bit_array
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should
import key/ed25519/private_key as ed25519_private_key
import key/ed25519/public_key as ed25519_public_key
import key/ed25519/signature as ed25519_signature
import key/public_key.{EcDsaPublicKey, EdDsaPublicKey}
import key/signature.{EcDsaSignature, EdDsaSignature}
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

pub fn regualar_webauthn_signature_proof_test() {
  // Data from https://github.com/nimiq/core-rs-albatross/blob/88723146a0aa7124b3bfb0651b6c1f57ea1f87c5/primitives/transaction/tests/basic_account_verify.rs#L49

  let public =
    EcDsaPublicKey(
      buf: bit_array.base16_decode(
        "02915782665472928bfe72c2869bbbd6bc0c239379d5a150ea5e2b19b205d53659",
      )
      |> result.lazy_unwrap(fn() { panic as "Invalid public key" }),
    )

  let signature =
    EcDsaSignature(
      buf: bit_array.base16_decode(
        "07b917e958f6fafcad747ac95e20ddf1ac63fc5d99bf4516e902e94591641084015ef7ed46034af18512743a0dcbc7a786aae27110b8cbd1cce81b062bd80c6e",
      )
      |> result.lazy_unwrap(fn() { panic as "Invalid signature" }),
    )

  let webauthn_fields =
    signature_proof.WebauthnFields(
      origin_json_str: "http://localhost:3000",
      has_cross_origin_field: True,
      client_data_extra_json: "",
      authenticator_data_suffix: bit_array.base16_decode("0165019a6c")
        |> result.lazy_unwrap(fn() {
          panic as "Invalid authenticator data suffix"
        }),
    )

  let proof =
    signature_proof.single_sig_webauthn(public, signature, webauthn_fields)

  let expected =
    bit_array.base16_decode(
      "1102915782665472928bfe72c2869bbbd6bc0c239379d5a150ea5e2b19b205d536590007b917e958f6fafcad747ac95e20ddf1ac63fc5d99bf4516e902e94591641084015ef7ed46034af18512743a0dcbc7a786aae27110b8cbd1cce81b062bd80c6e15687474703a2f2f6c6f63616c686f73743a333030300100050165019a6c",
    )
    |> result.lazy_unwrap(fn() { panic as "Invalid proof" })

  should.equal(signature_proof.serialize(proof), expected)

  let proof = case signature_proof.deserialize_all(expected) {
    Ok(proof) -> proof
    Error(err) -> panic as err
  }

  proof.public_key |> should.equal(public)
  proof.signature |> should.equal(signature)
  proof.webauthn_fields |> should.equal(Some(webauthn_fields))
}

pub fn android_chrome_webauthn_signature_proof_test() {
  // Data from https://github.com/nimiq/core-rs-albatross/blob/88723146a0aa7124b3bfb0651b6c1f57ea1f87c5/primitives/transaction/tests/basic_account_verify.rs#L73

  let public =
    EcDsaPublicKey(
      buf: bit_array.base16_decode(
        "0327e1f7995bde5df8a22bd9c27833b532d79c2350e61fc9a85621d1438eabeb7c",
      )
      |> result.lazy_unwrap(fn() { panic as "Invalid public key" }),
    )

  let signature =
    EcDsaSignature(
      buf: bit_array.base16_decode(
        "a4fe6e4e2990335d2e4ceeaf63ee149e2dc2e0703bc26f6323f4bebb454c7b505f5faf4fc5a47ea89bedf9d37786ce7e5355b179bdf13e9771ce426f13867a9d",
      )
      |> result.lazy_unwrap(fn() { panic as "Invalid signature" }),
    )

  let webauthn_fields =
    signature_proof.WebauthnFields(
      origin_json_str: "https:\\/\\/webauthn.pos.nimiqwatch.com",
      has_cross_origin_field: False,
      client_data_extra_json: ",\"androidPackageName\":\"com.android.chrome\"",
      authenticator_data_suffix: bit_array.base16_decode("0500000010")
        |> result.lazy_unwrap(fn() {
          panic as "Invalid authenticator data suffix"
        }),
    )

  let proof =
    signature_proof.single_sig_webauthn(public, signature, webauthn_fields)

  let expected =
    bit_array.base16_decode(
      "110327e1f7995bde5df8a22bd9c27833b532d79c2350e61fc9a85621d1438eabeb7c00a4fe6e4e2990335d2e4ceeaf63ee149e2dc2e0703bc26f6323f4bebb454c7b505f5faf4fc5a47ea89bedf9d37786ce7e5355b179bdf13e9771ce426f13867a9d2568747470733a5c2f5c2f776562617574686e2e706f732e6e696d697177617463682e636f6d002a2c22616e64726f69645061636b6167654e616d65223a22636f6d2e616e64726f69642e6368726f6d6522050500000010",
    )
    |> result.lazy_unwrap(fn() { panic as "Invalid proof" })

  should.equal(signature_proof.serialize(proof), expected)

  let proof = case signature_proof.deserialize_all(expected) {
    Ok(proof) -> proof
    Error(err) -> panic as err
  }

  proof.public_key |> should.equal(public)
  proof.signature |> should.equal(signature)
  proof.webauthn_fields |> should.equal(Some(webauthn_fields))
}
