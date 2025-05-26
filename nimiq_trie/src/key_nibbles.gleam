import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/string

import iv

import utils/serde

pub type KeyNibbles {
  KeyNibbles(nibbles: iv.Array(Int))
}

pub fn root() -> KeyNibbles {
  KeyNibbles(iv.new())
}

pub fn badbadbad() -> KeyNibbles {
  KeyNibbles(iv.from_list([0xb, 0xa, 0xd, 0xb, 0xa, 0xd, 0xb, 0xa, 0xd]))
}

pub fn len(key: KeyNibbles) -> Int {
  iv.length(key.nibbles)
}

pub fn is_empty(key: KeyNibbles) -> Bool {
  iv.is_empty(key.nibbles)
}

pub fn get(key: KeyNibbles, index: Int) -> Option(Int) {
  let length = len(key)
  case index {
    i if i >= length -> {
      case i != 0 {
        True ->
          io.println_error(
            "Index "
            <> i |> int.to_string()
            <> " exceeds the length of KeyNibbles "
            <> key |> to_string()
            <> ", which has length "
            <> length |> int.to_string()
            <> ".",
          )
        _ -> Nil
      }
      None
    }
    _ -> {
      iv.get(key.nibbles, index) |> option.from_result()
    }
  }
}

pub fn from_str(hex: String) -> Result(KeyNibbles, String) {
  case hex {
    "ε" -> Ok(root())
    _ -> {
      hex
      |> string.to_graphemes()
      |> list.map(fn(c) { c |> int.base_parse(16) })
      |> result.all()
      |> result.replace_error("Invalid hex string.")
      |> result.map(fn(nibbles) { KeyNibbles(iv.from_list(nibbles)) })
    }
  }
}

pub fn to_string(key: KeyNibbles) -> String {
  case len(key) {
    0 -> "ε"
    _ ->
      key.nibbles
      |> iv.fold("", fn(acc, nibble) { acc <> int.to_base16(nibble) })
      |> string.lowercase()
  }
}

pub fn add(key1: KeyNibbles, key2: KeyNibbles) -> KeyNibbles {
  iv.concat(key1.nibbles, key2.nibbles) |> KeyNibbles()
}

pub fn slice(key: KeyNibbles, start: Int, end: Int) -> KeyNibbles {
  iv.slice_clamped(key.nibbles, start, end - start) |> KeyNibbles()
}

pub fn suffix(key: KeyNibbles, start: Int) -> KeyNibbles {
  slice(key, start, len(key))
}

pub fn is_prefix_of(prefix check: KeyNibbles, of base: KeyNibbles) -> Bool {
  case base.nibbles |> iv.slice(0, len(check)) {
    Ok(slice) -> iv.equal(slice, check.nibbles)
    _ -> False
  }
}

pub fn common_prefix(key1: KeyNibbles, key2: KeyNibbles) -> KeyNibbles {
  case
    iv.zip(key1.nibbles, key2.nibbles)
    |> iv.find_index(fn(pair) {
      let #(left, right) = pair
      left != right
    })
  {
    Ok(index) -> slice(key1, 0, index)
    _ -> key1
  }
}

pub fn serialize(buf: BytesTree, key: KeyNibbles) -> BytesTree {
  let length = len(key)
  let byte_length = { length + 1 } / 2

  buf
  |> serde.serialize_u8(length)
  |> serde.serialize_u8(byte_length)
  |> serde.serialize_bitarray(case length {
    0 -> <<>>
    _ ->
      // Using a BitArray as a builder is not as efficient as using a BytesTree, but
      // BytesTrees cannot append half bytes without padding them in every append() call.
      // TODO: Optimize by using pairs of nibbles and bitwise adding them, to be able to use bytes_tree with full bytes.
      key.nibbles
      |> iv.fold(<<>>, fn(acc, nibble) { acc |> bit_array.append(<<nibble:4>>) })
      |> bit_array.pad_to_bytes()
  })
}

pub fn serialize_to_vec(key: KeyNibbles) -> BitArray {
  bytes_tree.new() |> serialize(key) |> bytes_tree.to_bit_array()
}

pub fn deserialize(buf: BitArray) -> Result(#(KeyNibbles, BitArray), String) {
  use #(length, rest) <- result.try(serde.deserialize_u8(buf))
  use #(byte_length, rest) <- result.try(serde.deserialize_u8(rest))
  case True {
    _ if byte_length != { length + 1 } / 2 ->
      Error(
        "Invalid byte length: expected "
        <> { length + 1 } / 2 |> int.to_string()
        <> ", got "
        <> byte_length |> int.to_string(),
      )
    _ -> {
      use #(bytes, rest) <- result.try(serde.deserialize_bitarray(
        rest,
        byte_length,
      ))
      // Convert the bytes to nibbles
      bytes
      |> bit_array.base16_encode()
      |> string.to_graphemes()
      |> list.map(fn(c) { c |> int.base_parse(16) })
      |> result.all()
      |> result.replace_error("Impossible error: invalid hex string.")
      |> result.map(fn(nibbles) {
        #(
          KeyNibbles(
            nibbles
            |> list.take(length)
            |> iv.from_list(),
          ),
          rest,
        )
      })
    }
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(KeyNibbles, String) {
  case deserialize(buf) {
    Ok(#(key, <<>>)) -> Ok(key)
    Ok(_) -> Error("Invalid KeyNibbles: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn equals(key1: KeyNibbles, key2: KeyNibbles) -> Bool {
  iv.equal(key1.nibbles, key2.nibbles)
}
