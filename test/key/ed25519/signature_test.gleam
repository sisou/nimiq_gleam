import dummy
import gleam/bit_array
import gleeunit/should
import key/ed25519/private_key
import key/ed25519/public_key
import key/ed25519/signature

pub fn create_signature_test() {
  let assert Ok(private) = private_key.from_hex(dummy.private_key_hex)
  let public = public_key.derive_key(private)

  signature.create(private, public, bit_array.from_string(dummy.message))
  |> signature.to_hex()
  |> should.equal(dummy.message_signature_hex)
}
