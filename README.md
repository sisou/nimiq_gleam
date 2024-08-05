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
import nimiq_gleam/transaction/enums.{TestAlbatrossNetwork}
import nimiq_gleam/transaction/signature_proof
import nimiq_gleam/transaction/transaction

let tx =
  let assert Ok(sender) =
    "NQ17 D2ES UBTP N14D RG4E 2KBK 217A 2GH2 NNY1"
    |> address.from_user_friendly_address()

  let assert Ok(recipient) =
    "NQ34 248H 248H 248H 248H 248H 248H 248H 248H"
    |> address.from_user_friendly_address()

  transaction.new_basic(
    sender,
    recipient,
    Coin(100_000_000), // Value in luna
    Coin(138), // Fee in luna
    100_000, // Validity start height
    TestAlbatrossNetwork, // Network ID
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
let tx =
  proof
  |> signature_proof.serialize()
  |> transaction.set_proof(tx, _)

// Print the serialized transaction as a hex string
io.println(transaction.to_hex(tx))
```

## CLI

Convert an address from any representation to user-friendly address format:

```sh
nimiq_gleam address 0000000000000000000000000000000000000000
# "NQ07 0000 0000 0000 0000 0000 0000 0000 0000"
```

<!-- Further documentation can be found at <https://hexdocs.pm/nimiq_gleam>. -->

## Development

```sh
gleam format # Format the code
gleam test   # Run the tests
gleam run    # Run the cli
```
