# ged25519

[![Package Version](https://img.shields.io/hexpm/v/ged25519)](https://hex.pm/packages/ged25519)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/ged25519/)

Ed25519 signature functions - Gleam bindings for the Elixir [`ed25519`](https://hex.pm/packages/ed25519) package.

```sh
gleam add ged25519@1
```
```gleam
import ged25519

pub fn main() -> Nil {
  // Generate a keypair
  let #(secret_key, public_key) = ged25519.generate_key_pair()

  // Derive a public key from a secret key
  let derived_public_key = ged25519.derive_public_key(secret_key)
  assert derived_public_key == public_key

  // Create a signature over a message
  let message = bit_array.from_string("Gleam rocks!")
  let signature = ged25519.signature(message, secret_key, public_key)

  // Verify a signature
  assert ged25519.valid_signature(signature, message, public_key) == True
}
```

Further documentation can be found at <https://hexdocs.pm/ged25519>.

## Development

```sh
gleam test  # Run the tests
```
