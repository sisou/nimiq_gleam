# Nimiq Trie

[![Package Version](https://img.shields.io/hexpm/v/nimiq_trie)](https://hex.pm/packages/nimiq_trie)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_trie/)

```sh
gleam add nimiq_trie@1
```

Further documentation can be found at <https://hexdocs.pm/nimiq_trie>.

## Development

```sh
gleam check # Compile the project
```

## Testing

For testing, you need a Redis-compatible KV store on localhost:6379.

```sh
# In one terminal:
docker run --rm -p 6379:6379 valkey/valkey

# In another terminal:
gleam test  # Run the tests
```
