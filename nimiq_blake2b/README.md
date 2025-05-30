# nimiq_blake2b

[![Package Version](https://img.shields.io/hexpm/v/nimiq_blake2b)](https://hex.pm/packages/nimiq_blake2b)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_blake2b/)

```sh
gleam add nimiq_blake2b@1
```
```gleam
import nimiq/blake2b

pub fn main() -> Nil {
"Nimiq rocks!"
  |> bit_array.from_string()
  |> blake2b.hash()
  |> bit_array.base16_encode()
  // -> "E493EE724B7D9D0AFE079DD7236DA36AB9DC5EF446AC16E52F232CF38A2CCB2F"
}
```

Further documentation can be found at <https://hexdocs.pm/nimiq_blake2b>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
