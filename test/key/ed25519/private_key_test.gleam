import dummy
import gleam/string
import gleeunit/should
import key/ed25519/private_key

pub fn generate_private_key_test() {
  let private = private_key.generate()

  private
  |> private_key.to_hex()
  |> string.length()
  |> should.equal(64)
}

pub fn import_private_key_test() {
  let assert Ok(private) = private_key.from_hex(dummy.private_key_hex)

  private
  |> private_key.to_hex()
  |> should.equal(dummy.private_key_hex)
}
