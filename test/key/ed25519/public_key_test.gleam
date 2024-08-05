import dummy
import gleeunit/should
import key/ed25519/private_key
import key/ed25519/public_key

pub fn derive_public_key_test() {
  let assert Ok(private) = private_key.from_hex(dummy.private_key_hex)

  private
  |> public_key.derive_key()
  |> public_key.to_hex()
  |> should.equal(dummy.public_key_hex)
}
