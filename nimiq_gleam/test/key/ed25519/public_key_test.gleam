import dummy
import gleeunit/should
import nimiq/address
import nimiq/key/ed25519/private_key
import nimiq/key/ed25519/public_key
import nimiq/key/public_key as pk

pub fn derive_public_key_test() {
  let assert Ok(private) = private_key.from_hex(dummy.private_key_hex)

  private
  |> public_key.derive_key()
  |> public_key.to_hex()
  |> should.equal(dummy.public_key_hex)
}

pub fn from_public_key_test() {
  let assert Ok(public) = public_key.from_hex(dummy.public_key_hex)

  pk.EdDsaPublicKey(public)
  |> pk.to_address()
  |> address.to_user_friendly_address()
  |> should.equal(dummy.address)
}
