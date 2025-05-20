import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/string
import iv

pub type KeyNibbles {
  KeyNibbles(nibbles: iv.Array(Int))
}

pub fn root() -> KeyNibbles {
  KeyNibbles(iv.new())
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
  case iv.slice(base.nibbles, 0, len(check)) {
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
