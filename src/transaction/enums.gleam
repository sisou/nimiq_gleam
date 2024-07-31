import gleam/int

pub type SignatureProofAlgorithm {
  Ed25519Algorithm
  ES256Algorithm
}

pub fn from_signature_algorithm(alg: SignatureProofAlgorithm) -> Int {
  case alg {
    Ed25519Algorithm -> 0
    ES256Algorithm -> 1
  }
}

pub fn to_signature_algorithm(
  alg: Int,
) -> Result(SignatureProofAlgorithm, String) {
  case alg {
    0 -> Ok(Ed25519Algorithm)
    1 -> Ok(ES256Algorithm)
    _ -> Error("Invalid signature proof algorithm: " <> int.to_string(alg))
  }
}

pub type NetworkId {
  TestAlbatrossNetwork
  MainAlbatrossNetwork
}

pub fn from_network_id(network_id: NetworkId) -> Int {
  case network_id {
    TestAlbatrossNetwork -> 5
    MainAlbatrossNetwork -> 24
  }
}

pub fn to_network_id(network_id: Int) -> Result(NetworkId, String) {
  case network_id {
    5 -> Ok(TestAlbatrossNetwork)
    24 -> Ok(MainAlbatrossNetwork)
    _ -> Error("Invalid network ID")
  }
}

pub type TransactionFormat {
  BasicFormat
  ExtendedFormat
}

pub fn from_transaction_format(format: TransactionFormat) -> Int {
  case format {
    BasicFormat -> 0
    ExtendedFormat -> 1
  }
}

pub fn to_transaction_format(format: Int) -> Result(TransactionFormat, String) {
  case format {
    0 -> Ok(BasicFormat)
    1 -> Ok(ExtendedFormat)
    _ -> Error("Invalid transaction format")
  }
}
