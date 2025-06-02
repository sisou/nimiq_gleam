# gvarint

[![Package Version](https://img.shields.io/hexpm/v/gvarint)](https://hex.pm/packages/gvarint)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gvarint/)

A library to compress unsigned integers using [LEB128](https://en.wikipedia.org/wiki/LEB128) - Gleam bindings for the Elixir [`varint`](https://hex.pm/packages/varint) package.

```sh
gleam add gvarint@1
```

```gleam
import gvarint

pub fn main() -> Nil {
  // Encode a number into a bitarray
  let bytes = gvarint.encode(120_000)
  // -> <<192, 169, 7>>

  // Decode a number from a bitarray
  let num = gvarint.decode(<<192, 169, 7>>)
  // -> #(120_000, <<>>)
}
```

## Development

```sh
gleam test  # Run the tests
```
