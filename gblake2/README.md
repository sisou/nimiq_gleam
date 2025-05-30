# gblake2

[![Package Version](https://img.shields.io/hexpm/v/gblake2)](https://hex.pm/packages/gblake2)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gblake2/)

Gleam bindings for the Elixir [`blake2`](https://hex.pm/packages/blake2) package.

```sh
gleam add gblake2@1
```
```gleam
import gblake2

pub fn main() -> Nil {
  "Nimiq rocks!"
  |> bit_array.from_string()
  // Hash a bitarray into a 32-byte hash
  |> gblake2.hash2b(32)
  |> bit_array.base16_encode()
  // -> "E493EE724B7D9D0AFE079DD7236DA36AB9DC5EF446AC16E52F232CF38A2CCB2F"
}
```

## Development

```sh
gleam test  # Run the tests
```
