import gleam/bytes_builder.{type BytesBuilder}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub fn encode(buf: BitArray, alphabet: String) -> String {
  do_encode(buf, alphabet, "")
}

fn do_encode(buf: BitArray, alphabet: String, acc: String) -> String {
  // Take each 5 bits of the buffer and decode them into characters
  let #(idx, rest) = case buf {
    <<char:5, rest:bits>> -> #(char, rest)
    // The following cases are not relevant for Nimiq addresses, as Nimiq addresses
    // are always 20 bytes, which is 160 bits and evenly divides by 5 bits.
    // They are included here for completeness.
    <<char:4, rest:bits>> -> #(int.bitwise_shift_left(char, 1), rest)
    <<char:3, rest:bits>> -> #(int.bitwise_shift_left(char, 2), rest)
    <<char:2, rest:bits>> -> #(int.bitwise_shift_left(char, 3), rest)
    <<char:1, rest:bits>> -> #(int.bitwise_shift_left(char, 4), rest)
    _ -> panic as "One recursion too many"
  }

  // Find the relevant character in the alphabet
  let char = string.slice(alphabet, idx, 1)

  case rest {
    // If rest is empty, return the accumulated string
    <<>> -> acc <> char
    // Otherwise recurse with the rest of the buffer and the accumulated string
    _ -> do_encode(rest, alphabet, acc <> char)
  }
}

pub fn decode(str: String, alphabet: String) -> Result(BitArray, String) {
  let decoded =
    str
    |> string.trim()
    |> string.to_graphemes()
    |> list.filter(fn(x) { x != "=" })
    |> do_decode(string.to_graphemes(alphabet), 0, bytes_builder.new())

  case decoded {
    Ok(bytes) -> Ok(bytes_builder.to_bit_array(bytes))
    Error(msg) -> Error(msg)
  }
}

fn do_decode(
  chars: List(String),
  alphabet: List(String),
  bit_length: Int,
  acc: BytesBuilder,
) -> Result(BytesBuilder, String) {
  let next_bit_length = bit_length + 5

  // Go through the characters and decode them into 5-bit numbers
  case chars {
    // When the list has been processed (is empty), return the accumulated bytes
    [] -> Ok(acc)
    // Special handling for last character to ensure correct byte-alignment
    // Not relevant for Nimiq Addresses, as their 32 characters = 160 bits evenly divide into bytes.
    // [char] -> {}
    [char, ..rest] -> {
      // Take the first character and find its index in the alphabet
      let idx = index_of(alphabet, char)
      case idx {
        Some(i) ->
          // Recurse with the rest of the characters and the accumulated bytes
          do_decode(
            rest,
            alphabet,
            next_bit_length,
            bytes_builder.append(acc, <<i:5>>),
          )
        None -> Error("Missing character in alphabet")
      }
    }
  }
}

fn index_of(list: List(a), elem: a) -> Option(Int) {
  do_index_of(list, elem, 0)
}

fn do_index_of(list: List(a), elem: a, index: Int) -> Option(Int) {
  case list {
    [] -> None
    [head, ..] if head == elem -> Some(index)
    [_, ..tail] -> do_index_of(tail, elem, index + 1)
  }
}
