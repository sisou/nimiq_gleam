# Nimiq for Gleam

[![Package Version](https://img.shields.io/hexpm/v/nimiq_gleam)](https://hex.pm/packages/nimiq_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/nimiq_gleam/)

Various modules and helpers for working with Nimiq primitives in the Gleam programming language or as a CLI.

## Installation

```sh
gleam add nimiq_gleam
```

## Address module

```gleam
import nimiq_gleam/account/address

pub fn main() {
  let formatted_addr =
    address.from_hex("0000000000000000000000000000000000000000")
    |> address.to_user_friendly_address()
  // = "NQ07 0000 0000 0000 0000 0000 0000 0000 0000"
}
```

## Key modules

```gleam
import nimiq_gleam/account/address
import nimiq_gleam/key/ed25519/private_key as private_key
import nimiq_gleam/key/ed25519/public_key as ed25519_public_key
import nimiq_gleam/key/public_key

// Generate a new private key
let private = private_key.generate()
// Print the private key in hex format
io.println(private_key.to_hex(private))
// Derive its public key
let public = ed25519_public_key.derive_key(private)
// Compute its address
let address = public_key.to_address(public)
// Print the address in user-friendly format
io.println(address.to_user_friendly_address(address))
```

## Transaction modules

```gleam
import gleam/option.{None}
import nimiq_gleam/account/address
import nimiq_gleam/coin.{Coin}
import nimiq_gleam/key/ed25519/private_key as private_key
import nimiq_gleam/key/ed25519/public_key as ed25519_public_key
import nimiq_gleam/key/ed25519/signature as ed25519_signature
import nimiq_gleam/key/public_key.{EdDsaPublicKey}
import nimiq_gleam/key/signature.{EdDsaSignature}
import nimiq_gleam/transaction/network_id
import nimiq_gleam/transaction/signature_proof
import nimiq_gleam/transaction/transaction

let assert Ok(sender) =
  "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1"
  |> address.from_user_friendly_address()

let assert Ok(recipient) =
  "NQ34 248H 248H 248H 248H 248H 248H 248H 248H"
  |> address.from_user_friendly_address()

let tx =
  transaction.new_basic(
    sender,
    recipient,
    Coin(100_000_000), // Value in luna
    Coin(138), // Fee in luna
    100_000, // Validity start height
    network_id.TestAlbatross, // Network ID
    None, // Flags
  )

// Construct signature proof
let assert Ok(private) =
  private_key.from_hex(
    "0000000000000000000000000000000000000000000000000000000000000000",
  )
let public_key = ed25519_public_key.derive_key(private_key)
let signature =
  ed25519_signature.create(
    private_key,
    public_key,
    transaction.serialize_content(tx),
  )
let proof = signature_proof.single_sig(
  EdDsaPublicKey(public_key),
  EdDsaSignature(signature),
)

// Add proof to transaction
let tx = transaction.set_signature_proof(tx, proof)

// Print the serialized transaction as a hex string
io.println(transaction.to_hex(tx))
```

## CLI

Use `--help` at the root or command level to see usage instructions.

### Address command

Convert an address from any string format to another string format.

```sh
# See usage instructions:
nimiq_gleam address --help

# From hex to user-friendly:
nimiq_gleam address 0000000000000000000000000000000000000000 --format=user-friendly
# Output:
# "NQ07 0000 0000 0000 0000 0000 0000 0000 0000"
```

### New-Tx command

Create and optionally sign transactions for Nimiq PoS.

```sh
# See usage instructions:
nimiq_gleam new-tx --help

# Create and optionally sign a transaction
nimiq_gleam new-tx \
  "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1" \
  "NQ34 248H 248H 248H 248H 248H 248H 248H 248H" \
  100000000 \
  100000 \
  --fee=138 \
  --msg="Nimiq rocks\!" \
  --sign-with=0000000000000000000000000000000000000000000000000000000000000000
# Output:
# 01689dae2f77b048dcc08e14d73104ea14222b5be1000011111111111111111111111111111111
# 11111111000c4e696d697120726f636b73210000000005f5e100000000000000008a000186a005
# 0062003b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da2900ae6c4c
# 8bc8b3cbf2e96a1845e846bc65e5e9d60d9989746cb14e7f0b195d77ec48eaaf592dc3720ba2d0
# 95fa7d15808c168b687cb0092e16f332f313ab45c609
```

<!-- Further documentation can be found at <https://hexdocs.pm/nimiq_gleam>. -->

## Development

```sh
gleam format # Format the code
gleam test   # Run the tests
gleam run    # Run the cli
```
