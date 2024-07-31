import gleam/float
import gleam/int

pub const decimals = 5

pub const lunas_per_coin = 100_000.0

pub type Coin {
  Coin(luna: Int)
}

pub fn lunas_to_coins(lunas: Coin) -> Float {
  int.to_float(lunas.luna) /. lunas_per_coin
}

pub fn coins_to_lunas(coins: Float) -> Coin {
  Coin(float.round(coins *. lunas_per_coin))
}
