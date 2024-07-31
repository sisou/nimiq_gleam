import dummy
import gleam/bit_array
import gleeunit/should
import key/ed25519/private_key
import key/ed25519/public_key
import key/ed25519/signature

pub fn create_signature_test() {
  case private_key.from_hex(dummy.private_key_hex) {
    Ok(private_key) -> {
      let public_key =
        private_key
        |> public_key.derive_key()

      signature.create(
        private_key,
        public_key,
        bit_array.from_string(dummy.message),
      )
      |> signature.to_hex()
      |> should.equal(dummy.message_signature_hex)
    }
    Error(_) -> should.fail()
  }
}
