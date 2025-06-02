/// Encodes an unsigned integer using LEB128 compression.
@external(erlang, "Elixir.Varint.LEB128", "encode")
pub fn encode(num num: Int) -> BitArray

/// Decodes LEB128 encoded bytes to an unsigned integer.
///
/// Returns a tuple where the first element is the decoded value and the second element the bytes which have not been
/// parsed.
///
/// This function will raise ArgumentError if the given bytes are not a valid LEB128 integer.
@external(erlang, "Elixir.Varint.LEB128", "decode")
pub fn decode(bytes b: BitArray) -> #(Int, BitArray)
