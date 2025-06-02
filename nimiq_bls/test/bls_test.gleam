import gleam/bit_array
import gleam/string
import nimiq/bls/compressed_public_key
import nimiq/bls/compressed_signature
import nimiq/bls/secret_key

pub const bls_secret_key_hex = "65100F4AA301DED3D9868C3D76052DD0DFEDE426B51AF371DCD8A4A076F11651C86286D2891063CE7B78217A6E163F38EBFDE7EB9DCBF5927B2278B00D77329141D44F070620DD6B995455A6CDFE8EEE03F657FF255CFB8FB3460CE1135701"

pub fn generate_bls_secret_key_test() {
  assert secret_key.generate()
    |> secret_key.serialize_to_bits()
    |> bit_array.base16_encode()
    |> string.length()
    == string.length(bls_secret_key_hex)
}

pub fn bls_public_key_test() {
  let assert Ok(secret_key) = bit_array.base16_decode(bls_secret_key_hex)
  let assert Ok(secret_key) = secret_key.deserialize_all(secret_key)

  assert secret_key
    |> compressed_public_key.derive_key()
    |> compressed_public_key.serialize_to_bits()
    |> bit_array.base16_encode()
    == "713C60858B5C72ADCF8B72B4DBEA959D042769DCC93A0190E4B8AEC92283548138833950AA214D920C17D3D19DE27F6176D9FB21620EDAE76AD398670E17D5EBA2F494B9B6901D457592EA68F9D35380C857BA44856AE037AFF272AD6C1900442B426DDE0BC53431E9CE5807F7EC4A05E71CE4A1E7E7B2511891521C4D3FD975764E3031EF646D48FA881AD88240813D40E533788F0DAC2BC4D4C25DB7B108C67DD28B7EC4C240CDC044BADCAED7860A5D3DA42EF860ED25A6DB9C07BE000A7F504F6D1B24AC81642206D5996B20749A156D7B39F851E60F228B19EEF3FB3547469F03FC9764F5F68BC88E187FFEE0F43F169ACDE847C78EA88029CDB19B91DD9562D60B607DD0347D67A0E33286C8908E4E9579A42685DA95F06A9201"
}

pub fn bls_signature_test() {
  let assert Ok(secret_key) = bit_array.base16_decode(bls_secret_key_hex)
  let assert Ok(secret_key) = secret_key.deserialize_all(secret_key)

  assert secret_key
    |> secret_key.proof_of_knowledge()
    |> compressed_signature.serialize_to_bits()
    |> bit_array.base16_encode()
    == "B7561C15E53DA2C482BFAFDDBF404F28B14EE2743E5CFE451C860DA378B2AC23A651B574183D1287E2CEA109943A34C44A7DF9EB2FE5067C70F1C02BDE900828C232A3D7736A278E0E8AC679BC2A1669F660C3810980526B7890F6E1708381"
}
