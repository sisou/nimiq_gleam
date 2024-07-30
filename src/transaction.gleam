import address.{type Address}
import gleam/bit_array
import gleam/bytes_builder
import nimiq_gleam/internal/varint

pub type AccountType {
  BasicAccount
  VestingContract
  HashedTimeLockedContract
  StakingContract
}

fn from_account_type(account_type: AccountType) -> Int {
  case account_type {
    BasicAccount -> 0
    VestingContract -> 1
    HashedTimeLockedContract -> 2
    StakingContract -> 3
  }
}

fn to_account_type(account_type: Int) -> Result(AccountType, String) {
  case account_type {
    0 -> Ok(BasicAccount)
    1 -> Ok(VestingContract)
    2 -> Ok(HashedTimeLockedContract)
    3 -> Ok(StakingContract)
    _ -> Error("Invalid account type")
  }
}

pub type Coin {
  Coin(luna: Int)
}

pub type NetworkId {
  TestAlbatrossNetwork
  MainAlbatrossNetwork
}

fn from_network_id(network_id: NetworkId) -> Int {
  case network_id {
    TestAlbatrossNetwork -> 5
    MainAlbatrossNetwork -> 24
  }
}

fn to_network_id(network_id: Int) -> Result(NetworkId, String) {
  case network_id {
    5 -> Ok(TestAlbatrossNetwork)
    24 -> Ok(MainAlbatrossNetwork)
    _ -> Error("Invalid network ID")
  }
}

pub type TransactionFlags {
  NoneFlag
  ContractCreationFlag
  SignalingFlag
}

fn from_transaction_flags(flags: TransactionFlags) -> Int {
  case flags {
    NoneFlag -> 0b00000000
    ContractCreationFlag -> 0b00000001
    SignalingFlag -> 0b00000010
  }
}

fn to_transaction_flags(flags: Int) -> Result(TransactionFlags, String) {
  case flags {
    0b00000000 -> Ok(NoneFlag)
    0b00000001 -> Ok(ContractCreationFlag)
    0b00000010 -> Ok(SignalingFlag)
    _ -> Error("Invalid transaction flags")
  }
}

pub type TransactionFormat {
  BasicFormat
  ExtendedFormat
}

fn from_transaction_format(format: TransactionFormat) -> Int {
  case format {
    BasicFormat -> 0
    ExtendedFormat -> 1
  }
}

fn to_transaction_format(format: Int) -> Result(TransactionFormat, String) {
  case format {
    0 -> Ok(BasicFormat)
    1 -> Ok(ExtendedFormat)
    _ -> Error("Invalid transaction format")
  }
}

pub opaque type Transaction {
  Transaction(
    sender: Address,
    sender_type: AccountType,
    sender_data: BitArray,
    recipient: Address,
    recipient_type: AccountType,
    recipient_data: BitArray,
    value: Coin,
    fee: Coin,
    validity_start_height: Int,
    network_id: NetworkId,
    flags: TransactionFlags,
    proof: BitArray,
  )
}

pub fn new_basic(
  sender: Address,
  recipient: Address,
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    BasicAccount,
    <<>>,
    recipient,
    BasicAccount,
    <<>>,
    value,
    fee,
    validity_start_height,
    network_id,
    NoneFlag,
    <<>>,
  )
}

pub fn format(tx: Transaction) -> TransactionFormat {
  case
    tx.sender_type == BasicAccount
    && tx.recipient_type == BasicAccount
    && tx.recipient_data == <<>>
    && tx.flags == NoneFlag
  {
    True -> {
      // TODO: If proof exists, check for empty merkle_path and that the proof's public key is the sender address
      BasicFormat
    }
    False -> ExtendedFormat
  }
}

pub fn serialize_content(tx: Transaction) -> BitArray {
  bytes_builder.new()
  // Recipient data
  |> bytes_builder.append(<<bit_array.byte_size(tx.recipient_data):16>>)
  |> bytes_builder.append(tx.recipient_data)
  // Sender
  |> bytes_builder.append(address.serialize(tx.sender))
  |> bytes_builder.append(<<from_account_type(tx.sender_type):8>>)
  // Recipient
  |> bytes_builder.append(address.serialize(tx.recipient))
  |> bytes_builder.append(<<from_account_type(tx.recipient_type):8>>)
  // Value & fee
  |> bytes_builder.append(<<tx.value.luna:64>>)
  |> bytes_builder.append(<<tx.fee.luna:64>>)
  // Validity start height
  |> bytes_builder.append(<<tx.validity_start_height:32>>)
  // Network ID
  |> bytes_builder.append(<<from_network_id(tx.network_id):8>>)
  // Flags
  |> bytes_builder.append(<<from_transaction_flags(tx.flags):8>>)
  // Sender data
  |> bytes_builder.append(varint.encode(bit_array.byte_size(tx.sender_data)))
  |> bytes_builder.append(tx.sender_data)
  // Convert to bit array
  |> bytes_builder.to_bit_array()
}

pub fn serialize(tx: Transaction) -> BitArray {
  let buf = bytes_builder.new()

  let format = format(tx) |> from_transaction_format()
  bytes_builder.append(buf, <<format:8>>)

  todo
}

pub fn to_hex(tx: Transaction) -> String {
  serialize(tx) |> bit_array.base16_encode()
}

pub fn deserialize(buf: BitArray) -> Result(Transaction, String) {
  todo
}

pub fn from_hex(str: String) -> Result(Transaction, String) {
  todo
}
