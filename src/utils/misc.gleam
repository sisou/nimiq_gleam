import gleam/bit_array
import gleam/string

/// For when you really know the Result cannot be Error
pub fn unwrap(res: Result(a, _)) -> a {
  case res {
    Ok(a) -> a
    Error(_) -> panic as "Called unwrap on an Error value"
  }
}

pub fn to_hex(buf: BitArray) -> String {
  buf |> bit_array.base16_encode() |> string.lowercase()
}
