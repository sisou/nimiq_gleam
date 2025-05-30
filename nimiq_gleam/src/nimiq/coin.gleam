import gleam/bytes_tree.{type BytesTree}
import gleam/float
import gleam/int
import gleam/result
import nimiq/serde

pub const decimals = 5

pub const lunas_per_coin = 100_000.0

pub type Coin {
  Coin(luna: Int)
}

pub fn zero() -> Coin {
  Coin(0)
}

pub fn lunas_to_coins(lunas: Coin) -> Float {
  int.to_float(lunas.luna) /. lunas_per_coin
}

pub fn coins_to_lunas(coins: Float) -> Coin {
  Coin(float.round(coins *. lunas_per_coin))
}

pub fn serialize(builder: BytesTree, coin: Coin) -> BytesTree {
  builder |> serde.serialize_u64(coin.luna)
}

pub fn serialize_to_vec(coin: Coin) -> BitArray {
  bytes_tree.new() |> serialize(coin) |> bytes_tree.to_bit_array()
}

pub fn deserialize(buf: BitArray) -> Result(#(Coin, BitArray), String) {
  use #(luna, rest) <- result.try(serde.deserialize_u64(buf))
  Ok(#(Coin(luna), rest))
}

pub fn deserialize_all(buf: BitArray) -> Result(Coin, String) {
  case deserialize(buf) {
    Ok(#(coin, <<>>)) -> Ok(coin)
    Ok(_) -> Error("Invalid coin: trailing bytes")
    Error(err) -> Error(err)
  }
}
