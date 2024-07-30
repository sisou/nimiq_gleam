# Nimiq for Gleam

[![Package Version](https://img.shields.io/hexpm/v/nimiq_gleam)](https://hex.pm/packages/nimiq_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_gleam/)

Various modules and helpers for working with Nimiq primitives in the Gleam programming language or as a CLI.

## Installation

```sh
gleam add nimiq_gleam
```

## CLI

Convert an address from any representation to user-friendly address format:

```sh
nimiq_gleam address 0000000000000000000000000000000000000000
# "NQ07 0000 0000 0000 0000 0000 0000 0000 0000"
```

## Address module

```gleam
import nimiq_gleam/address

pub fn main() {
  let formatted_addr =
    address.from_hex("0000000000000000000000000000000000000000")
    |> address.to_user_friendly_address()
  // = "NQ07 0000 0000 0000 0000 0000 0000 0000 0000"
}
```

<!-- Further documentation can be found at <https://hexdocs.pm/nimiq_gleam>. -->

## Development

```sh
gleam format # Format the code
gleam test   # Run the tests
gleam run    # Run the cli
```
