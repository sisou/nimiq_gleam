/// Public or secret key
pub type Key =
  BitArray

/// Computed signature
pub type Signature =
  BitArray

/// Derive the public signing key from the secret key
@external(erlang, "Elixir.Ed25519", "derive_public_key")
pub fn derive_public_key(secret_key sk: Key) -> Key

/// Generate a secret/public key pair
///
/// Returned tuple contains `#(random_secret_key, derived_public_key)`
@external(erlang, "Elixir.Ed25519", "generate_key_pair")
pub fn generate_key_pair() -> #(Key, Key)

/// Derive a secret/public key pair from supplied secret key
///
/// Returned tuple contains `#(secret_key, derived_public_key)`
@external(erlang, "Elixir.Ed25519.Ed25519", "generate_key_pair")
pub fn derive_key_pair(secret_key secret: Key) -> #(Key, Key)

/// Returns whether a given `key` lies on the ed25519 curve.
@external(erlang, "Elixir.Ed25519", "on_curve?")
pub fn on_curve(key key: Key) -> Bool

/// Sign a message
@external(erlang, "Elixir.Ed25519", "signature")
pub fn signature(
  message m: BitArray,
  secret_key sk: Key,
  public_key pk: Key,
) -> Signature

// /// Derive the x25519/curve25519 encryption key from the ed25519 signing key
// ///
// /// By converting an `EdwardsPoint` on the Edwards model to the corresponding `MontgomeryPoint` on the Montgomery model
// ///
// /// Handles either :secret or :public keys as indicated in the call
// ///
// /// May `raise` on an invalid input key or unknown atom
// ///
// /// See: https://blog.filippo.io/using-ed25519-keys-for-encryption
// @external(erlang, "Elixir.Ed25519.Ed25519", "to_curve25519")
// pub fn to_curve25519(key: Key, which: String) -> Key

/// Validate a signed message
@external(erlang, "Elixir.Ed25519", "valid_signature?")
pub fn valid_signature(
  signature sig: Signature,
  message m: BitArray,
  public_key pk: Key,
) -> Bool
