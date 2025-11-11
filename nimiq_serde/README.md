# nimiq_serde

[![Package Version](https://img.shields.io/hexpm/v/nimiq_serde)](https://hex.pm/packages/nimiq_serde)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_serde/)

Serialization and deserialization helpers in Gleam.

```sh
gleam add nimiq_serde@1
```
```gleam
import gleam/bytes_tree
import nimiq/serde

pub fn main() -> Nil {
  // Serialize some data
  let buf =
    bytes_tree.new()
    |> serde.serialize_u8(42)
    |> serde.serialize_bool(True)
    |> serde.serialize_u32(65_535)
    |> serde.serialize_string("Hello, Gleam!")
    |> bytes_tree.to_bit_array()

  // Deserialize the same data
  let assert Ok(#(num_u8, buf)) = serde.deserialize_u8(buf)
  let assert Ok(#(bool_val, buf)) = serde.deserialize_bool(buf)
  let assert Ok(#(num_u32, buf)) = serde.deserialize_u32(buf)
  let assert Ok(#(str, rest)) = serde.deserialize_string(buf)
}
```

Further documentation can be found at <https://hexdocs.pm/nimiq_serde>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
