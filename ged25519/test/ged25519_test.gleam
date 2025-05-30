import ged25519
import gleam/bit_array
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

pub const private_key_hex = "E2D1F619126D734D309C78B5D623A96ECABD84E032386BDAE89CB61D52597388"

pub fn derive_public_key_test() {
  let assert Ok(private) = bit_array.base16_decode(private_key_hex)

  ged25519.derive_public_key(private)
  |> bit_array.base16_encode()
  |> should.equal(
    "A0505F600B4DB76FF0430056AEB3DB1628A26780751A513B66E68566A14A3A6C",
  )
}

pub fn signature_test() {
  let assert Ok(private) = bit_array.base16_decode(private_key_hex)

  let public_key = ged25519.derive_public_key(private)
  let message = bit_array.from_string("Nimiq rocks!")

  ged25519.signature(message, private, public_key)
  |> bit_array.base16_encode()
  |> should.equal(
    "93E88AC207998A4C545F240805C1CE6AC9FCB1148D5505952376C6DF415C8907BD8698809A3550C71B37E3CAF71C9C9AFF6075AD7E59DFEF8ECA2BA5A1CE7902",
  )
}
