import gleam/int

pub type NetworkId {
  TestAlbatross
  UnitAlbatross
  MainAlbatross
}

pub fn to_int(network_id: NetworkId) -> Int {
  case network_id {
    TestAlbatross -> 5
    UnitAlbatross -> 7
    MainAlbatross -> 24
  }
}

pub fn from_int(value: Int) -> Result(NetworkId, String) {
  case value {
    5 -> Ok(TestAlbatross)
    7 -> Ok(UnitAlbatross)
    24 -> Ok(MainAlbatross)
    _ -> Error("Invalid network ID: " <> int.to_string(value))
  }
}
