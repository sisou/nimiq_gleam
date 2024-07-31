import bindings/ed25519
import dummy
import gleam/bit_array
import gleam/string
import gleeunit/should

pub fn derive_public_key_test() {
  case bit_array.base16_decode(dummy.private_key_hex) {
    Ok(private_key) -> {
      let public_key = ed25519.derive_public_key(private_key)
      should.equal(
        bit_array.base16_encode(public_key) |> string.lowercase(),
        dummy.public_key_hex,
      )
    }
    Error(_) -> should.fail()
  }
}

pub fn signature_test() {
  case bit_array.base16_decode(dummy.private_key_hex) {
    Ok(private_key) -> {
      let public_key = ed25519.derive_public_key(private_key)
      let message = bit_array.from_string(dummy.message)
      let signature = ed25519.signature(message, private_key, public_key)
      should.equal(
        bit_array.base16_encode(signature) |> string.lowercase(),
        dummy.message_signature_hex,
      )
    }
    Error(_) -> should.fail()
  }
}
