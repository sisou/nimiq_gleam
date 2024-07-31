import dummy
import gleam/string
import gleeunit/should
import key/ed25519/private_key

pub fn generate_private_key_test() {
  let private_key = private_key.generate()

  private_key
  |> private_key.to_hex()
  |> string.length()
  |> should.equal(64)
}

pub fn import_private_key_test() {
  case private_key.from_hex(dummy.private_key_hex) {
    Ok(private_key) ->
      private_key
      |> private_key.to_hex()
      |> should.equal(dummy.private_key_hex)
    Error(_) -> should.fail()
  }
}
