// Bindings for https://hex.pm/packages/blake2

/// Blake2b hashing
///
/// Note that the `output_size` is in bytes, not bits
///
/// - 64 => Blake2b-512 (default)
/// - 48 => Blake2b-384
/// - 32 => Blake2b-256
///
/// Per the specification, any `output_size` between 1 and 64 bytes is supported.
@external(erlang, "Elixir.Blake2", "hash2b")
pub fn hash2b(m: BitArray, output_size: Int) -> BitArray
