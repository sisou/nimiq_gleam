# nimiq_address

[![Package Version](https://img.shields.io/hexpm/v/nimiq_address)](https://hex.pm/packages/nimiq_address)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_address/)

Nimiq Address implementation for Gleam.

```sh
gleam add nimiq_address@1
```
```gleam
import nimiq_address

pub fn main() -> Nil {
  // Convert from HEX to user-friendly format
  let address = address.from_string("0000000000000000000000000000000000000000")
    |> result.map(address.to_user_friendly_address)
  // Ok("NQ07 0000 0000 0000 0000 0000 0000 0000 0000")

  // Convert from user-friendly to HEX format
  let address = address.from_string("NQ07 0000 0000 0000 0000 0000 0000 0000 0000")
    |> result.map(address.to_hex)
  // Ok("0000000000000000000000000000000000000000")

  // Encode with a custom country code
  let address = address.from_hex("64e8e01142a6ccc1265189e95ad72e17586fe4ad")
    |> result.map(fn(address) {
      address |> address.to_user_friendly_address_ccode("CC")
    })
  // Ok("CC34 CKLE 04A2 LT6C 29JH H7LM MMRE 2VC6 YR5D")
}
```

Further documentation can be found at <https://hexdocs.pm/nimiq_address>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
