# Nimiq BLS

[![Package Version](https://img.shields.io/hexpm/v/nimiq_bls)](https://hex.pm/packages/nimiq_bls)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_bls/)

Nimiq-style BLS keys and signatures for Gleam. Uses FFI-bindings to [Nimiq's Rust code](https://github.com/nimiq/core-rs-albatross).

```sh
gleam add nimiq_bls@1
```
```gleam
import nimiq/bls/compressed_public_key
import nimiq/bls/compressed_signature
import nimiq/bls/secret_key

pub fn main() -> Nil {
  let bls_secret_key = secret_key.generate()
  let bls_public_key = bls_secret_key |> compressed_public_key.derive_key()
  let bls_signature = bls_secret_key |> secret_key.proof_of_knowledge()
}
```

Further documentation can be found at <https://hexdocs.pm/nimiq_bls>.

## Development

```sh
gleam test  # Run the tests
```
