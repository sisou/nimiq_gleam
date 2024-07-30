import address
import gleeunit/should

pub fn from_hex_to_userfriendly_test() {
  case address.from_string("0000000000000000000000000000000000000000") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ07 0000 0000 0000 0000 0000 0000 0000 0000")
    Error(_) -> should.fail()
  }

  case address.from_string("64e8e01142a6ccc1265189e95ad72e17586fe4ad") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D")
    Error(_) -> should.fail()
  }

  case address.from_string("c8b572c0343d5370d6738553cdd1401a84526235") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ15 R2SP 5G1L 7M9P 1MKK GM9U TLA0 3A25 4QHM")
    Error(_) -> should.fail()
  }

  case address.from_string("611be1b1195e35ae1797f23d9be7b88001f4d3ed") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ08 C4DX 3C8R BQSS U5UP X8XR PRVQ G00Y 9LYD")
    Error(_) -> should.fail()
  }

  case address.from_string("92d6d085874314d3bb612e4c84814ba4160242ff") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ40 JBBD 11C7 8CAD 7ET1 5R68 90AB LGB0 4GPY")
    Error(_) -> should.fail()
  }

  case address.from_string("352bf5bcb58ba9d424b10a91b2c73ed7a2057d57") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ96 6LMY BF5M HELV 895H 1A8T 5HRX SXH0 AYAP")
    Error(_) -> should.fail()
  }

  case address.from_string("ca9b7171ca4abb00e79ae63f6dccf16f2db6726f") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ34 RADP 2UEA 9AVG 1RUS UQYN TK7H DUNT CUKF")
    Error(_) -> should.fail()
  }

  case address.from_string("c810122d58d06102104eeec7d6ea70b005cdb258") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ12 R081 4BAQ S1GG 442E VT3V DSKG N02U TCJQ")
    Error(_) -> should.fail()
  }
}

pub fn from_userfriendly_to_hex_test() {
  case address.from_string("NQ07 0000 0000 0000 0000 0000 0000 0000 0000") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("0000000000000000000000000000000000000000")
    Error(_) -> should.fail()
  }

  case address.from_string("NQ87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("64e8e01142a6ccc1265189e95ad72e17586fe4ad")
    Error(_) -> should.fail()
  }

  case address.from_string("NQ15 R2SP 5G1L 7M9P 1MKK GM9U TLA0 3A25 4QHM") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("c8b572c0343d5370d6738553cdd1401a84526235")
    Error(_) -> should.fail()
  }

  case address.from_string("NQ08 C4DX 3C8R BQSS U5UP X8XR PRVQ G00Y 9LYD") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("611be1b1195e35ae1797f23d9be7b88001f4d3ed")
    Error(_) -> should.fail()
  }

  case address.from_string("NQ40 JBBD 11C7 8CAD 7ET1 5R68 90AB LGB0 4GPY") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("92d6d085874314d3bb612e4c84814ba4160242ff")
    Error(_) -> should.fail()
  }

  case address.from_string("NQ96 6LMY BF5M HELV 895H 1A8T 5HRX SXH0 AYAP") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("352bf5bcb58ba9d424b10a91b2c73ed7a2057d57")
    Error(_) -> should.fail()
  }

  case address.from_string("NQ34 RADP 2UEA 9AVG 1RUS UQYN TK7H DUNT CUKF") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("ca9b7171ca4abb00e79ae63f6dccf16f2db6726f")
    Error(_) -> should.fail()
  }

  case address.from_string("NQ12 R081 4BAQ S1GG 442E VT3V DSKG N02U TCJQ") {
    Ok(addr) ->
      address.to_hex(addr)
      |> should.equal("c810122d58d06102104eeec7d6ea70b005cdb258")
    Error(_) -> should.fail()
  }
}

pub fn decoding_errors_test() {
  // Invalid hex encoding
  should.equal(
    address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4a"),
    Error("Invalid address: not a valid hex encoding"),
  )
  should.equal(
    address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4ag"),
    Error("Invalid address: not a valid hex encoding"),
  )
  should.equal(
    address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4add"),
    Error("Invalid address: not a valid hex encoding"),
  )

  // Invalid ccode
  should.equal(
    address.from_user_friendly_address(
      "NI87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    ),
    Error("Invalid address: wrong country code"),
  )
  should.equal(
    address.from_user_friendly_address(
      "NIL87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    ),
    Error("Invalid address: wrong country code"),
  )
  should.equal(
    address.from_user_friendly_address(
      "N87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    ),
    Error("Invalid address: wrong country code"),
  )

  // Invalid checksum
  should.equal(
    address.from_user_friendly_address(
      "NQ86 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    ),
    Error("Invalid address: wrong checksum"),
  )
  should.equal(
    address.from_user_friendly_address(
      "NQ00 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    ),
    Error("Invalid address: wrong checksum"),
  )
  should.equal(
    address.from_user_friendly_address(
      "NQ CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D",
    ),
    Error("Invalid address: wrong length"),
  )

  // Invalid base32 encoding
  should.equal(
    address.from_user_friendly_address(
      "NQ81 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5O",
    ),
    Error("Invalid address: not a valid user friendly encoding"),
  )
  should.equal(
    address.from_user_friendly_address(
      "NQ75 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5Z",
    ),
    Error("Invalid address: not a valid user friendly encoding"),
  )
  should.equal(
    address.from_user_friendly_address(
      "NQ87 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR",
    ),
    Error("Invalid address: wrong length"),
  )
}
