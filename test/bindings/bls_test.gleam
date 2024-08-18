import bindings/bls
import dummy
import gleam/bit_array
import gleam/string
import gleeunit/should
import utils/misc

pub fn generate_bls_secret_key_test() {
  bls.generate_secret_key()
  |> bls.secret_key_to_bytes()
  |> misc.to_hex()
  |> string.length()
  |> should.equal(string.length(dummy.bls_secret_key_hex))
}

pub fn bls_public_key_test() {
  let assert Ok(secret_key) = bit_array.base16_decode(dummy.bls_secret_key_hex)
  let assert Ok(secret_key) = bls.secret_key_from_bytes(secret_key)

  secret_key
  |> bls.derive_public_key()
  |> bls.public_key_to_bytes()
  |> misc.to_hex()
  |> should.equal(dummy.bls_public_key_hex)
}

pub fn bls_signature_test() {
  let assert Ok(secret_key) = bit_array.base16_decode(dummy.bls_secret_key_hex)
  let assert Ok(secret_key) = bls.secret_key_from_bytes(secret_key)

  bls.derive_public_key(secret_key)
  |> bls.create_proof_of_knowledge(secret_key, _)
  |> bls.signature_to_bytes()
  |> misc.to_hex()
  |> should.equal(dummy.bls_proof_of_knowledge_hex)
}
