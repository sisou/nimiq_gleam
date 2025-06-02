import dummy
import gleam/string
import nimiq/key/ed25519/private_key

pub fn generate_private_key_test() {
  let private = private_key.generate()

  let assert 64 =
    private
    |> private_key.to_hex()
    |> string.length()
}

pub fn import_private_key_test() {
  let assert Ok(private) = private_key.from_hex(dummy.private_key_hex)

  assert private |> private_key.to_hex() == dummy.private_key_hex
}
