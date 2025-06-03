import gleam/result
import gleeunit
import nimiq/address

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn from_hex_to_userfriendly_test() {
  assert address.from_string("0000000000000000000000000000000000000000")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ07 0000 0000 0000 0000 0000 0000 0000 0000")

  assert address.from_string("64e8e01142a6ccc1265189e95ad72e17586fe4ad")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D")

  assert address.from_string("c8b572c0343d5370d6738553cdd1401a84526235")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ15 R2SP 5G1L 7M9P 1MKK GM9U TLA0 3A25 4QHM")

  assert address.from_string("611be1b1195e35ae1797f23d9be7b88001f4d3ed")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ08 C4DX 3C8R BQSS U5UP X8XR PRVQ G00Y 9LYD")

  assert address.from_string("92d6d085874314d3bb612e4c84814ba4160242ff")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ40 JBBD 11C7 8CAD 7ET1 5R68 90AB LGB0 4GPY")

  assert address.from_string("352bf5bcb58ba9d424b10a91b2c73ed7a2057d57")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ96 6LMY BF5M HELV 895H 1A8T 5HRX SXH0 AYAP")

  assert address.from_string("ca9b7171ca4abb00e79ae63f6dccf16f2db6726f")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ34 RADP 2UEA 9AVG 1RUS UQYN TK7H DUNT CUKF")

  assert address.from_string("c810122d58d06102104eeec7d6ea70b005cdb258")
    |> result.map(address.to_user_friendly_address)
    == Ok("NQ12 R081 4BAQ S1GG 442E VT3V DSKG N02U TCJQ")
}

pub fn from_userfriendly_to_hex_test() {
  assert address.from_string("NQ07 0000 0000 0000 0000 0000 0000 0000 0000")
    |> result.map(address.to_hex)
    == Ok("0000000000000000000000000000000000000000")

  assert address.from_string("NQ87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D")
    |> result.map(address.to_hex)
    == Ok("64e8e01142a6ccc1265189e95ad72e17586fe4ad")

  assert address.from_string("NQ15 R2SP 5G1L 7M9P 1MKK GM9U TLA0 3A25 4QHM")
    |> result.map(address.to_hex)
    == Ok("c8b572c0343d5370d6738553cdd1401a84526235")

  assert address.from_string("NQ08 C4DX 3C8R BQSS U5UP X8XR PRVQ G00Y 9LYD")
    |> result.map(address.to_hex)
    == Ok("611be1b1195e35ae1797f23d9be7b88001f4d3ed")

  assert address.from_string("NQ40 JBBD 11C7 8CAD 7ET1 5R68 90AB LGB0 4GPY")
    |> result.map(address.to_hex)
    == Ok("92d6d085874314d3bb612e4c84814ba4160242ff")

  assert address.from_string("NQ96 6LMY BF5M HELV 895H 1A8T 5HRX SXH0 AYAP")
    |> result.map(address.to_hex)
    == Ok("352bf5bcb58ba9d424b10a91b2c73ed7a2057d57")

  assert address.from_string("NQ34 RADP 2UEA 9AVG 1RUS UQYN TK7H DUNT CUKF")
    |> result.map(address.to_hex)
    == Ok("ca9b7171ca4abb00e79ae63f6dccf16f2db6726f")

  assert address.from_string("NQ12 R081 4BAQ S1GG 442E VT3V DSKG N02U TCJQ")
    |> result.map(address.to_hex)
    == Ok("c810122d58d06102104eeec7d6ea70b005cdb258")
}

pub fn decoding_errors_test() {
  // Invalid hex encoding
  assert address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4a")
    == Error("Invalid address: not a valid hex encoding")
  assert address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4ag")
    == Error("Invalid address: not a valid hex encoding")
  assert address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4add")
    == Error("Invalid address: not a valid hex encoding")

  // Invalid ccode
  assert address.from_user_friendly_address(
      "NI87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    )
    == Error("Invalid address: wrong country code")
  assert address.from_user_friendly_address(
      "NIL87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    )
    == Error("Invalid address: wrong country code")
  assert address.from_user_friendly_address(
      "N87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    )
    == Error("Invalid address: wrong country code")

  // Invalid checksum
  assert address.from_user_friendly_address(
      "NQ86 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    )
    == Error("Invalid address: wrong checksum")
  assert address.from_user_friendly_address(
      "NQ00 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    )
    == Error("Invalid address: wrong checksum")
  assert address.from_user_friendly_address(
      "NQ CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    )
    == Error("Invalid address: wrong length")

  // Invalid base32 encoding
  assert address.from_user_friendly_address(
      "NQ81 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5O",
    )
    == Error("Invalid address: not a valid user friendly encoding")
  assert address.from_user_friendly_address(
      "NQ75 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5Z",
    )
    == Error("Invalid address: not a valid user friendly encoding")
  assert address.from_user_friendly_address(
      "NQ87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR",
    )
    == Error("Invalid address: wrong length")
}

pub fn zero_test() {
  assert address.zero()
    |> address.to_user_friendly_address()
    == "NQ07 0000 0000 0000 0000 0000 0000 0000 0000"

  assert address.staking_contract()
    |> address.to_user_friendly_address()
    == "NQ77 0000 0000 0000 0000 0000 0000 0000 0001"
}

pub fn custom_ccode_test() {
  let assert Ok(address) =
    address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4ad")
  assert address
    |> address.to_user_friendly_address_ccode("CC")
    == "CC34 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D"
}
