import dummy
import gleam/bit_array
import gleeunit/should
import nimiq/key/ed25519/private_key
import nimiq/key/ed25519/public_key
import nimiq/key/ed25519/signature

pub fn create_signature_test() {
  let assert Ok(private) = private_key.from_hex(dummy.private_key_hex)
  let public = public_key.derive_key(private)

  signature.create(private, public, bit_array.from_string("Nimiq rocks!"))
  |> signature.to_hex()
  |> should.equal(
    "93e88ac207998a4c545f240805c1ce6ac9fcb1148d5505952376c6df415c8907bd8698809a3550c71b37e3caf71c9c9aff6075ad7e59dfef8eca2ba5a1ce7902",
  )
}
