import bls/compressed_public_key
import bls/compressed_signature
import bls/secret_key
import dummy
import gleam/bit_array
import gleam/string
import gleeunit/should
import utils/misc

pub fn generate_bls_secret_key_test() {
  secret_key.generate()
  |> secret_key.serialize_to_bits()
  |> misc.to_hex()
  |> string.length()
  |> should.equal(string.length(dummy.bls_secret_key_hex))
}

pub fn bls_public_key_test() {
  let assert Ok(secret_key) = bit_array.base16_decode(dummy.bls_secret_key_hex)
  let assert Ok(secret_key) = secret_key.deserialize_all(secret_key)

  secret_key
  |> compressed_public_key.derive_key()
  |> compressed_public_key.serialize_to_bits()
  |> misc.to_hex()
  |> should.equal(dummy.bls_public_key_hex)
}

pub fn bls_signature_test() {
  let assert Ok(secret_key) = bit_array.base16_decode(dummy.bls_secret_key_hex)
  let assert Ok(secret_key) = secret_key.deserialize_all(secret_key)

  secret_key
  |> secret_key.proof_of_knowledge()
  |> compressed_signature.serialize_to_bits()
  |> misc.to_hex()
  |> should.equal(dummy.bls_proof_of_knowledge_hex)
}
