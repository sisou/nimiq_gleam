import bindings/ed25519
import dummy
import gleam/bit_array
import gleeunit/should
import utils/misc

pub fn derive_public_key_test() {
  let assert Ok(private) = bit_array.base16_decode(dummy.private_key_hex)

  ed25519.derive_public_key(private)
  |> misc.to_hex()
  |> should.equal(dummy.public_key_hex)
}

pub fn signature_test() {
  let assert Ok(private) = bit_array.base16_decode(dummy.private_key_hex)

  let public_key = ed25519.derive_public_key(private)
  let message = bit_array.from_string(dummy.message)

  ed25519.signature(message, private, public_key)
  |> misc.to_hex()
  |> should.equal(dummy.message_signature_hex)
}
