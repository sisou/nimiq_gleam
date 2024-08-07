import gleam/int

pub type NetworkId {
  TestAlbatross
  MainAlbatross
}

pub fn to_int(network_id: NetworkId) -> Int {
  case network_id {
    TestAlbatross -> 5
    MainAlbatross -> 24
  }
}

pub fn from_int(value: Int) -> Result(NetworkId, String) {
  case value {
    5 -> Ok(TestAlbatross)
    24 -> Ok(MainAlbatross)
    _ -> Error("Invalid network ID: " <> int.to_string(value))
  }
}
