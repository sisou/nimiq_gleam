import dummy
import gleeunit/should
import key/ed25519/private_key
import key/ed25519/public_key

pub fn derive_public_key_test() {
  case private_key.from_hex(dummy.private_key_hex) {
    Ok(private_key) ->
      private_key
      |> public_key.derive_key()
      |> public_key.to_hex()
      |> should.equal(dummy.public_key_hex)
    Error(_) -> should.fail()
  }
}
