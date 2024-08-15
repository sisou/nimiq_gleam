import account/account_type
import account/address.{type Address}
import coin.{type Coin}
import gleam/option.{type Option, None, Some}
import key/ed25519/public_key as ed25519_public_key
import policy
import transaction/network_id.{type NetworkId}
import transaction/signature_proof
import transaction/staking_data
import transaction/transaction.{type Transaction, Transaction}
import transaction/transaction_flags

pub fn new_basic(
  sender: Address,
  recipient: Address,
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
  proof: Option(BitArray),
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    recipient,
    account_type.Basic,
    <<>>,
    value,
    fee,
    validity_start_height,
    network_id,
    None,
    option.unwrap(proof, <<>>),
  )
}

pub fn new_basic_with_data(
  sender: Address,
  recipient: Address,
  data: BitArray,
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
  proof: Option(BitArray),
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    recipient,
    account_type.Basic,
    data,
    value,
    fee,
    validity_start_height,
    network_id,
    None,
    option.unwrap(proof, <<>>),
  )
}

// pub fn new_create_vesting() -> Transaction {
//   todo
// }

// pub fn new_redeem_vesting() -> Transaction {
//   todo
// }

// pub fn new_create_htlc() -> Transaction {
//   todo
// }

// pub fn new_redeem_htlc_regular() -> Transaction {
//   todo
// }

// pub fn new_redeem_htlc_timeout() -> Transaction {
//   todo
// }

// pub fn new_redeem_htlc_early() -> Transaction {
//   todo
// }

// pub fn sign_htlc_early() -> SignatureProof {
//   todo
// }

pub fn new_create_staker(
  sender: Address,
  delegation: Option(Address),
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.CreateStaker(delegation, signature_proof.default())
      |> staking_data.serialize_to_bits(),
    value,
    fee,
    validity_start_height,
    network_id,
    None,
    <<>>,
  )
}

pub fn new_add_stake(
  sender: Address,
  staker_address: Address,
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.AddStake(staker_address)
      |> staking_data.serialize_to_bits(),
    value,
    fee,
    validity_start_height,
    network_id,
    None,
    <<>>,
  )
}

pub fn new_update_staker(
  sender: Address,
  new_delegation: Option(Address),
  reactivate_all_stake: Bool,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.UpdateStaker(
      new_delegation,
      reactivate_all_stake,
      signature_proof.default(),
    )
      |> staking_data.serialize_to_bits(),
    coin.zero(),
    fee,
    validity_start_height,
    network_id,
    Some(transaction_flags.Signaling),
    <<>>,
  )
}

pub fn new_set_active_stake(
  sender: Address,
  new_active_balance: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.SetActiveStake(new_active_balance, signature_proof.default())
      |> staking_data.serialize_to_bits(),
    coin.zero(),
    fee,
    validity_start_height,
    network_id,
    Some(transaction_flags.Signaling),
    <<>>,
  )
}

pub fn new_retire_stake(
  sender: Address,
  retire_stake: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.RetireStake(retire_stake, signature_proof.default())
      |> staking_data.serialize_to_bits(),
    coin.zero(),
    fee,
    validity_start_height,
    network_id,
    Some(transaction_flags.Signaling),
    <<>>,
  )
}

pub fn new_remove_stake(
  recipient: Address,
  value: Coin,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    address.staking_contract(),
    account_type.Staking,
    <<staking_data.to_int(staking_data.RemoveStake)>>,
    recipient,
    account_type.Basic,
    <<>>,
    value,
    fee,
    validity_start_height,
    network_id,
    None,
    <<>>,
  )
}

pub fn new_create_validator(
  sender: Address,
  signing_public_key: ed25519_public_key.PublicKey,
  voting_public_key: staking_data.BlsPublicKey,
  proof_of_knowledge: staking_data.BlsSignature,
  reward_address: Address,
  signal_data: Option(staking_data.Blake2bHash),
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.CreateValidator(
      signing_public_key,
      voting_public_key,
      reward_address,
      signal_data,
      proof_of_knowledge,
      signature_proof.default(),
    )
      |> staking_data.serialize_to_bits(),
    policy.validator_deposit,
    fee,
    validity_start_height,
    network_id,
    None,
    <<>>,
  )
}

pub fn new_update_validator(
  sender: Address,
  new_signing_public_key: Option(ed25519_public_key.PublicKey),
  new_voting_public_key: Option(staking_data.BlsPublicKey),
  new_proof_of_knowledge: Option(staking_data.BlsSignature),
  new_reward_address: Option(Address),
  new_signal_data: Option(Option(staking_data.Blake2bHash)),
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.UpdateValidator(
      new_signing_public_key,
      new_voting_public_key,
      new_reward_address,
      new_signal_data,
      new_proof_of_knowledge,
      signature_proof.default(),
    )
      |> staking_data.serialize_to_bits(),
    coin.zero(),
    fee,
    validity_start_height,
    network_id,
    Some(transaction_flags.Signaling),
    <<>>,
  )
}

pub fn new_deactivate_validator(
  sender: Address,
  validator_address: Address,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.DeactivateValidator(
      validator_address,
      signature_proof.default(),
    )
      |> staking_data.serialize_to_bits(),
    coin.zero(),
    fee,
    validity_start_height,
    network_id,
    Some(transaction_flags.Signaling),
    <<>>,
  )
}

pub fn new_reactivate_validator(
  sender: Address,
  validator_address: Address,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.ReactivateValidator(
      validator_address,
      signature_proof.default(),
    )
      |> staking_data.serialize_to_bits(),
    coin.zero(),
    fee,
    validity_start_height,
    network_id,
    Some(transaction_flags.Signaling),
    <<>>,
  )
}

pub fn new_retire_validator(
  sender: Address,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    sender,
    account_type.Basic,
    <<>>,
    address.staking_contract(),
    account_type.Staking,
    staking_data.RetireValidator(signature_proof.default())
      |> staking_data.serialize_to_bits(),
    coin.zero(),
    fee,
    validity_start_height,
    network_id,
    Some(transaction_flags.Signaling),
    <<>>,
  )
}

pub fn new_delete_validator(
  recipient: Address,
  fee: Coin,
  validity_start_height: Int,
  network_id: NetworkId,
) -> Transaction {
  Transaction(
    address.staking_contract(),
    account_type.Staking,
    <<staking_data.to_int(staking_data.DeleteValidator)>>,
    recipient,
    account_type.Basic,
    <<>>,
    policy.validator_deposit,
    fee,
    validity_start_height,
    network_id,
    None,
    <<>>,
  )
}