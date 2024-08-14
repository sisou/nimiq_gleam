import account/address.{type Address}
import coin.{type Coin}
import gleam/bytes_builder.{type BytesBuilder}
import gleam/option.{type Option, None, Some}
import gleam/result
import key/ed25519/public_key.{type PublicKey as Ed25519PublicKey}
import transaction/signature_proof.{type SignatureProof}
import utils/misc
import utils/serde

pub type Blake2bHash =
  BitArray

/// Length: 285 bytes
pub type BlsPublicKey =
  BitArray

/// Length: 95 bytes
pub type BlsSignature =
  BitArray

pub type StakingData {
  CreateValidator(
    signing_key: Ed25519PublicKey,
    voting_key: BlsPublicKey,
    reward_address: Address,
    signal_data: Option(Blake2bHash),
    proof_of_knowledge: BlsSignature,
    /// This proof is signed with the validator cold key, which will become the validator address.
    proof: SignatureProof,
  )
  UpdateValidator(
    new_signing_key: Option(Ed25519PublicKey),
    new_voting_key: Option(BlsPublicKey),
    new_reward_address: Option(Address),
    new_signal_data: Option(Option(Blake2bHash)),
    new_proof_of_knowledge: Option(BlsSignature),
    /// This proof is signed with the validator cold key.
    proof: SignatureProof,
  )
  DeactivateValidator(
    validator_address: Address,
    /// This proof is signed with the validator warm key.
    proof: SignatureProof,
  )
  ReactivateValidator(
    validator_address: Address,
    /// This proof is signed with the validator warm key.
    proof: SignatureProof,
  )
  RetireValidator(
    /// This proof is signed with the validator cold key.
    proof: SignatureProof,
  )
  CreateStaker(delegation: Option(Address), proof: SignatureProof)
  AddStake(staker_address: Address)
  UpdateStaker(
    new_delegation: Option(Address),
    reactivate_all_stake: Bool,
    proof: SignatureProof,
  )
  SetActiveStake(new_active_balance: Coin, proof: SignatureProof)
  RetireStake(retire_stake: Coin, proof: SignatureProof)
}

pub fn deserialize(buf: BitArray) -> Result(#(StakingData, BitArray), String) {
  use #(format, rest) <- result.try(serde.deserialize_int(buf, 8))
  case format {
    0 -> {
      // CreateValidator
      use #(signing_key, rest) <- result.try(public_key.deserialize(rest))
      use #(voting_key, rest) <- result.try(serde.deserialize_bitarray(
        rest,
        285,
      ))
      use #(reward_address, rest) <- result.try(address.deserialize(rest))
      use #(has_signal_data, rest) <- result.try(serde.deserialize_bool(rest))
      use #(signal_data, rest) <- result.try(case has_signal_data {
        False -> Ok(#(None, rest))
        True ->
          serde.deserialize_bitarray(rest, 32)
          |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
      })
      use #(proof_of_knowledge, rest) <- result.try(serde.deserialize_bitarray(
        rest,
        95,
      ))
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(
        CreateValidator(
          signing_key,
          voting_key,
          reward_address,
          signal_data,
          proof_of_knowledge,
          proof,
        ),
        rest,
      ))
    }
    1 -> {
      // UpdateValidator
      use #(has_new_signing_key, rest) <- result.try(serde.deserialize_bool(
        rest,
      ))
      use #(new_signing_key, rest) <- result.try(case has_new_signing_key {
        False -> Ok(#(None, rest))
        True ->
          public_key.deserialize(rest)
          |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
      })
      use #(has_new_voting_key, rest) <- result.try(serde.deserialize_bool(rest))
      use #(new_voting_key, rest) <- result.try(case has_new_voting_key {
        False -> Ok(#(None, rest))
        True ->
          serde.deserialize_bitarray(rest, 285)
          |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
      })
      use #(has_new_reward_address, rest) <- result.try(serde.deserialize_bool(
        rest,
      ))
      use #(new_reward_address, rest) <- result.try(case
        has_new_reward_address
      {
        False -> Ok(#(None, rest))
        True ->
          address.deserialize(rest)
          |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
      })
      use #(has_new_signal_data, rest) <- result.try(serde.deserialize_bool(
        rest,
      ))
      use #(new_signal_data, rest) <- result.try(case has_new_signal_data {
        False -> Ok(#(None, rest))
        True -> {
          use #(has_signal_data, rest) <- result.try(serde.deserialize_bool(
            rest,
          ))
          use #(signal_data, rest) <- result.try(case has_signal_data {
            False -> Ok(#(None, rest))
            True ->
              serde.deserialize_bitarray(rest, 32)
              |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
          })

          Ok(#(Some(signal_data), rest))
        }
      })
      use #(has_new_proof_of_knowledge, rest) <- result.try(
        serde.deserialize_bool(rest),
      )
      use #(new_proof_of_knowledge, rest) <- result.try(case
        has_new_proof_of_knowledge
      {
        False -> Ok(#(None, rest))
        True ->
          serde.deserialize_bitarray(rest, 95)
          |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
      })
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(
        UpdateValidator(
          new_signing_key,
          new_voting_key,
          new_reward_address,
          new_signal_data,
          new_proof_of_knowledge,
          proof,
        ),
        rest,
      ))
    }
    2 -> {
      // DeactivateValidator
      use #(validator_address, rest) <- result.try(address.deserialize(rest))
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(DeactivateValidator(validator_address, proof), rest))
    }
    3 -> {
      // ReactivateValidator
      use #(validator_address, rest) <- result.try(address.deserialize(rest))
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(ReactivateValidator(validator_address, proof), rest))
    }
    4 -> {
      // RetireValidator
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(RetireValidator(proof), rest))
    }
    5 -> {
      // CreateStaker
      use #(has_delegation, rest) <- result.try(serde.deserialize_bool(rest))
      use #(delegation, rest) <- result.try(case has_delegation {
        False -> Ok(#(None, rest))
        True ->
          address.deserialize(rest)
          |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
      })
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(CreateStaker(delegation, proof), rest))
    }
    6 -> {
      // AddStake
      use #(staker_address, rest) <- result.try(address.deserialize(rest))

      Ok(#(AddStake(staker_address), rest))
    }
    7 -> {
      // UpdateStaker
      use #(has_new_delegation, rest) <- result.try(serde.deserialize_bool(rest))
      use #(new_delegation, rest) <- result.try(case has_new_delegation {
        False -> Ok(#(None, rest))
        True ->
          address.deserialize(rest)
          |> result.map(fn(tuple) { #(Some(tuple.0), tuple.1) })
      })
      use #(reactivate_all_stake, rest) <- result.try(serde.deserialize_bool(
        rest,
      ))
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(UpdateStaker(new_delegation, reactivate_all_stake, proof), rest))
    }
    8 -> {
      // SetActiveStake
      use #(new_active_balance, rest) <- result.try(serde.deserialize_coin(rest))
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(SetActiveStake(new_active_balance, proof), rest))
    }
    9 -> {
      // RetireStake
      use #(retire_stake, rest) <- result.try(serde.deserialize_coin(rest))
      use #(proof, rest) <- result.try(signature_proof.deserialize(rest))

      Ok(#(RetireStake(retire_stake, proof), rest))
    }
    _ -> Error("Invalid staking data type")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(StakingData, String) {
  case deserialize(buf) {
    Ok(#(data, <<>>)) -> Ok(data)
    Ok(_) -> Error("Invalid staking data: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn serialize(builder: BytesBuilder, data: StakingData) -> BytesBuilder {
  case data {
    CreateValidator(
      signing_key,
      voting_key,
      reward_address,
      signal_data,
      proof_of_knowledge,
      proof,
    ) -> {
      let builder =
        builder
        |> serde.serialize_int(0, 8)
        |> public_key.serialize(signing_key)
        |> serde.serialize_bitarray(voting_key)
        |> address.serialize(reward_address)
        |> serde.serialize_bool(option.is_some(signal_data))
      let builder = case signal_data {
        None -> builder
        Some(data) -> builder |> serde.serialize_bitarray(data)
      }
      builder
      |> serde.serialize_bitarray(proof_of_knowledge)
      |> signature_proof.serialize(proof)
    }
    UpdateValidator(
      new_signing_key,
      new_voting_key,
      new_reward_address,
      new_signal_data,
      new_proof_of_knowledge,
      proof,
    ) -> {
      let builder =
        builder
        |> serde.serialize_int(1, 8)
        |> serde.serialize_bool(option.is_some(new_signing_key))
      let builder = case new_signing_key {
        None -> builder
        Some(key) -> builder |> public_key.serialize(key)
      }
      let builder =
        builder |> serde.serialize_bool(option.is_some(new_voting_key))
      let builder = case new_voting_key {
        None -> builder
        Some(key) -> builder |> serde.serialize_bitarray(key)
      }
      let builder =
        builder |> serde.serialize_bool(option.is_some(new_reward_address))
      let builder = case new_reward_address {
        None -> builder
        Some(address) -> builder |> address.serialize(address)
      }
      let builder =
        builder |> serde.serialize_bool(option.is_some(new_signal_data))
      let builder = case new_signal_data {
        None -> builder
        Some(signal_data) -> {
          let builder =
            builder |> serde.serialize_bool(option.is_some(signal_data))
          case signal_data {
            None -> builder
            Some(signal_data) ->
              builder |> serde.serialize_bitarray(signal_data)
          }
        }
      }
      let builder =
        builder |> serde.serialize_bool(option.is_some(new_proof_of_knowledge))
      let builder = case new_proof_of_knowledge {
        None -> builder
        Some(proof) -> builder |> serde.serialize_bitarray(proof)
      }
      builder |> signature_proof.serialize(proof)
    }
    DeactivateValidator(validator_address, proof) -> {
      builder
      |> serde.serialize_int(2, 8)
      |> address.serialize(validator_address)
      |> signature_proof.serialize(proof)
    }
    ReactivateValidator(validator_address, proof) -> {
      builder
      |> serde.serialize_int(3, 8)
      |> address.serialize(validator_address)
      |> signature_proof.serialize(proof)
    }
    RetireValidator(proof) -> {
      builder
      |> serde.serialize_int(4, 8)
      |> signature_proof.serialize(proof)
    }
    CreateStaker(delegation, proof) -> {
      let builder =
        builder
        |> serde.serialize_int(5, 8)
        |> serde.serialize_bool(option.is_some(delegation))
      let builder = case delegation {
        None -> builder
        Some(address) -> builder |> address.serialize(address)
      }
      builder |> signature_proof.serialize(proof)
    }
    AddStake(staker_address) -> {
      builder
      |> serde.serialize_int(6, 8)
      |> address.serialize(staker_address)
    }
    UpdateStaker(new_delegation, reactivate_all_stake, proof) -> {
      let builder =
        builder
        |> serde.serialize_int(7, 8)
        |> serde.serialize_bool(option.is_some(new_delegation))
      let builder = case new_delegation {
        None -> builder
        Some(address) -> builder |> address.serialize(address)
      }
      builder
      |> serde.serialize_bool(reactivate_all_stake)
      |> signature_proof.serialize(proof)
    }
    SetActiveStake(new_active_balance, proof) -> {
      builder
      |> serde.serialize_int(8, 8)
      |> serde.serialize_coin(new_active_balance)
      |> signature_proof.serialize(proof)
    }
    RetireStake(retire_stake, proof) -> {
      builder
      |> serde.serialize_int(9, 8)
      |> serde.serialize_coin(retire_stake)
      |> signature_proof.serialize(proof)
    }
  }
}

pub fn serialize_to_bits(data: StakingData) -> BitArray {
  bytes_builder.new() |> serialize(data) |> bytes_builder.to_bit_array()
}

pub fn to_hex(data: StakingData) -> String {
  data |> serialize_to_bits() |> misc.to_hex()
}
