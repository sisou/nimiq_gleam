/// Blake2b hashing
///
/// Note that the `output_size` is in bytes, not bits
///
/// - 64 => Blake2b-512
/// - 48 => Blake2b-384
/// - 32 => Blake2b-256
///
/// Per the specification, any `output_size` between 1 and 64 bytes is supported.
@external(erlang, "Elixir.Blake2", "hash2b")
pub fn hash2b(message m: BitArray, output_size output_size: Int) -> BitArray

/// Blake2b hashing
///
/// Note that the `output_size` is in bytes, not bits
///
/// - 64 => Blake2b-512
/// - 48 => Blake2b-384
/// - 32 => Blake2b-256
///
/// Per the specification, any `output_size` between 1 and 64 bytes is supported.
@external(erlang, "Elixir.Blake2", "hash2b")
pub fn hash2b_secret(
  message m: BitArray,
  output_size output_size: Int,
  secret_key secret_key: BitArray,
) -> BitArray

/// Blake2s hashing
///
/// Note that the output_size is in bytes, not bits
///
/// - 32 => Blake2s-256
/// - 24 => Blake2b-192
/// - 16 => Blake2b-128
///
/// Per the specification, any output_size between 1 and 32 bytes is supported.
@external(erlang, "Elixir.Blake2", "hash2s")
pub fn hash2s(message m: BitArray, output_size output_size: Int) -> BitArray

/// Blake2s hashing
///
/// Note that the output_size is in bytes, not bits
///
/// - 32 => Blake2s-256
/// - 24 => Blake2b-192
/// - 16 => Blake2b-128
///
/// Per the specification, any output_size between 1 and 32 bytes is supported.
@external(erlang, "Elixir.Blake2", "hash2s")
pub fn hash2s_secret(
  message m: BitArray,
  output_size output_size: Int,
  secret_key secret_key: BitArray,
) -> BitArray
