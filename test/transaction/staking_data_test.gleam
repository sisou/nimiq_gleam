import account/address
import gleam/bit_array
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should
import key/ed25519/private_key as ed25519_private_key
import key/ed25519/public_key as ed25519_public_key
import transaction/signature_proof
import transaction/staking_data
import utils/misc

pub fn create_validator_serialization_test() {
  let assert Ok(private_key) =
    ed25519_private_key.from_string(
      "b410a7a583cbc13ef4f1cbddace30928bcb4f9c13722414bc4a2faaba3f4e187",
    )
  let public_key = ed25519_public_key.derive_key(private_key)
  let assert Ok(bls_compressed_public_key) =
    bit_array.base16_decode(
      "1c958b6a7c96e13d29310d38e34865201218184086799b79cf0f80d3355ba143fedcaf388cb9b4e4a7e68a268ce7fe3c3fc6ef6bbc593d9aaa33db86c3a2d897651e1314e2acac88646521c4cb429b5ddeace58f447d0499305d67f2022f01a94ed0b2b4a1a65484334acda69cac9c2d58828ea896915e43df1f5df02a507a6bd2c4c1fe543845a6087d130f6da2c1fdaf8081d0b7bce595426e8636a1e38c9716c7617e998b3227720a800fcd752331648db0838ce4ad9afd0ee44b7100337c52058162ded9ee0db85766129423344db96c0e7459e3dd429237f8e51da68d34c9112aa177820d1071ba6fbc947e497791f3047333dc5b60c5ef09ad11086550b81b94c21e5957f8e63c0ff61fc31a1eb30d1b42f006e49ab850e54a00",
    )
  let assert Ok(address) =
    address.from_string("9cd82948650d902d95d52ea2ec91eae6deb0c9fe")
  let assert Ok(data) =
    bit_array.base16_decode(
      "0000000000000000000000000000000000000000000000000000000000000000",
    )
  let assert Ok(bls_proof_of_knowledge) =
    bit_array.base16_decode(
      "5913c5a6c205888ff1ebc4f3458d143eaac340fecff400c26d32f2cee23f33eb7a2d895988f421f7dd925cb5d77c69878d91a51bd658496d215c57584fac3f887bc1043f6f6649f5cae27f89ca62b318237585d83acc2e1abf18244bea3481",
    )

  let assert Ok(Ok(signature_proof)) =
    bit_array.base16_decode(
      "007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500e01683caf07ce31f6517cda348b0a49f08abf4adc2d464c0577b374b51a084d278d5a8b6e9780b5e724172472cbb957f16ce0cc565cd4c40f16939a91e9b8602",
    )
    |> result.map(signature_proof.deserialize_all)

  let serialized =
    staking_data.CreateValidator(
      public_key,
      bls_compressed_public_key,
      address,
      Some(data),
      bls_proof_of_knowledge,
      signature_proof,
    )
    |> staking_data.serialize_to_bits()

  let assert "007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec051c958b6a7c96e13d29310d38e34865201218184086799b79cf0f80d3355ba143fedcaf388cb9b4e4a7e68a268ce7fe3c3fc6ef6bbc593d9aaa33db86c3a2d897651e1314e2acac88646521c4cb429b5ddeace58f447d0499305d67f2022f01a94ed0b2b4a1a65484334acda69cac9c2d58828ea896915e43df1f5df02a507a6bd2c4c1fe543845a6087d130f6da2c1fdaf8081d0b7bce595426e8636a1e38c9716c7617e998b3227720a800fcd752331648db0838ce4ad9afd0ee44b7100337c52058162ded9ee0db85766129423344db96c0e7459e3dd429237f8e51da68d34c9112aa177820d1071ba6fbc947e497791f3047333dc5b60c5ef09ad11086550b81b94c21e5957f8e63c0ff61fc31a1eb30d1b42f006e49ab850e54a009cd82948650d902d95d52ea2ec91eae6deb0c9fe0100000000000000000000000000000000000000000000000000000000000000005913c5a6c205888ff1ebc4f3458d143eaac340fecff400c26d32f2cee23f33eb7a2d895988f421f7dd925cb5d77c69878d91a51bd658496d215c57584fac3f887bc1043f6f6649f5cae27f89ca62b318237585d83acc2e1abf18244bea3481007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500e01683caf07ce31f6517cda348b0a49f08abf4adc2d464c0577b374b51a084d278d5a8b6e9780b5e724172472cbb957f16ce0cc565cd4c40f16939a91e9b8602" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.CreateValidator(
    signing_key,
    voting_key,
    reward_address,
    signal_data,
    proof_of_knowledge,
    proof,
  )) = staking_data.deserialize_all(serialized)

  should.equal(signing_key, public_key)
  should.equal(voting_key, bls_compressed_public_key)
  should.equal(reward_address, address)
  should.equal(signal_data, Some(data))
  should.equal(proof_of_knowledge, bls_proof_of_knowledge)
  should.equal(proof, signature_proof)
}

pub fn update_validator_serialization_test() {
  let assert Ok(private_key) =
    ed25519_private_key.from_string(
      "b410a7a583cbc13ef4f1cbddace30928bcb4f9c13722414bc4a2faaba3f4e187",
    )
  let public_key = ed25519_public_key.derive_key(private_key)
  let assert Ok(address) =
    address.from_string("9cd82948650d902d95d52ea2ec91eae6deb0c9fe")
  let assert Ok(Ok(signature_proof)) =
    bit_array.base16_decode(
      "007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500c5d91a24e67f6494e838df0141b2b2be1f5a5fb02bdba73694450fbd0a1afda26167635b71a55a2b5dae0c8d3bff54073935cc8b46233af22f0c5e96c7701408",
    )
    |> result.map(signature_proof.deserialize_all)

  let serialized =
    staking_data.UpdateValidator(
      Some(public_key),
      None,
      Some(address),
      None,
      None,
      signature_proof,
    )
    |> staking_data.serialize_to_bits()

  let assert "01017f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500019cd82948650d902d95d52ea2ec91eae6deb0c9fe0000007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500c5d91a24e67f6494e838df0141b2b2be1f5a5fb02bdba73694450fbd0a1afda26167635b71a55a2b5dae0c8d3bff54073935cc8b46233af22f0c5e96c7701408" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.UpdateValidator(
    new_signing_key,
    new_voting_key,
    new_reward_address,
    new_signal_data,
    new_proof_of_knowledge,
    proof,
  )) = staking_data.deserialize_all(serialized)

  should.equal(new_signing_key, Some(public_key))
  should.equal(new_voting_key, None)
  should.equal(new_reward_address, Some(address))
  should.equal(new_signal_data, None)
  should.equal(new_proof_of_knowledge, None)
  should.equal(proof, signature_proof)
}

pub fn deactivate_validator_serialization_test() {
  let assert Ok(address) =
    address.from_string("9cd82948650d902d95d52ea2ec91eae6deb0c9fe")
  let assert Ok(Ok(signature_proof)) =
    bit_array.base16_decode(
      "007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec05008ea73e63a245c6a628461565283359fa3b59c2020bcfccbbfeef0a932b68bbd5d0ac931ae2cb84db9135dc466fd9a1ef597c5d8ab2115c21d01d7a1ef120a60b",
    )
    |> result.map(signature_proof.deserialize_all)

  let serialized =
    staking_data.DeactivateValidator(address, signature_proof)
    |> staking_data.serialize_to_bits()

  let assert "029cd82948650d902d95d52ea2ec91eae6deb0c9fe007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec05008ea73e63a245c6a628461565283359fa3b59c2020bcfccbbfeef0a932b68bbd5d0ac931ae2cb84db9135dc466fd9a1ef597c5d8ab2115c21d01d7a1ef120a60b" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.DeactivateValidator(validator_address, proof)) =
    staking_data.deserialize_all(serialized)

  should.equal(validator_address, address)
  should.equal(proof, signature_proof)
}

pub fn reactivate_validator_serialization_test() {
  let assert Ok(address) =
    address.from_string("9cd82948650d902d95d52ea2ec91eae6deb0c9fe")
  let assert Ok(Ok(signature_proof)) =
    bit_array.base16_decode(
      "007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec050053022215b85ecaeace4f0619a3d11b25b2b20755e27d4b24c2b42849816f9f973b7c9f3604b9814fecc39f62fc547780538decb1637f45ae9f374654abe03500",
    )
    |> result.map(signature_proof.deserialize_all)

  let serialized =
    staking_data.ReactivateValidator(address, signature_proof)
    |> staking_data.serialize_to_bits()

  let assert "039cd82948650d902d95d52ea2ec91eae6deb0c9fe007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec050053022215b85ecaeace4f0619a3d11b25b2b20755e27d4b24c2b42849816f9f973b7c9f3604b9814fecc39f62fc547780538decb1637f45ae9f374654abe03500" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.ReactivateValidator(validator_address, proof)) =
    staking_data.deserialize_all(serialized)

  should.equal(validator_address, address)
  should.equal(proof, signature_proof)
}

pub fn retire_validator_serialization_test() {
  let assert Ok(Ok(signature_proof)) =
    bit_array.base16_decode(
      "00b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a84400214acc4c13b8563a1b03ca59ebc18fde38a668e3250d72d7d826d6c6398da9f5558e4a1f9ad179e17c3c82203c4691b8500be81d9bd150b60e8b1dc6c434870d",
    )
    |> result.map(signature_proof.deserialize_all)

  let serialized =
    staking_data.RetireValidator(signature_proof)
    |> staking_data.serialize_to_bits()

  let assert "0400b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a84400214acc4c13b8563a1b03ca59ebc18fde38a668e3250d72d7d826d6c6398da9f5558e4a1f9ad179e17c3c82203c4691b8500be81d9bd150b60e8b1dc6c434870d" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.RetireValidator(proof)) =
    staking_data.deserialize_all(serialized)

  should.equal(proof, signature_proof)
}

pub fn create_staker_serialization_test() {
  let assert Ok(address) =
    address.from_string("9cd82948650d902d95d52ea2ec91eae6deb0c9fe")
  let assert Ok(Ok(signature_proof)) =
    bit_array.base16_decode(
      "007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500ef97d321d26fa105a1c2ab8fb83d7ce96b098cda93ede580c1e0e26f2859bfaaa37ef0432cc2093d37d72f02aed153e4fc28530ef8a0e948e64bac257a2a5402",
    )
    |> result.map(signature_proof.deserialize_all)

  let serialized =
    staking_data.CreateStaker(Some(address), signature_proof)
    |> staking_data.serialize_to_bits()

  let assert "05019cd82948650d902d95d52ea2ec91eae6deb0c9fe007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500ef97d321d26fa105a1c2ab8fb83d7ce96b098cda93ede580c1e0e26f2859bfaaa37ef0432cc2093d37d72f02aed153e4fc28530ef8a0e948e64bac257a2a5402" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.CreateStaker(delegation, proof)) =
    staking_data.deserialize_all(serialized)

  should.equal(delegation, Some(address))
  should.equal(proof, signature_proof)
}

pub fn add_stake_serialization_test() {
  let assert Ok(address) =
    address.from_string("9cd82948650d902d95d52ea2ec91eae6deb0c9fe")

  let serialized =
    staking_data.AddStake(address)
    |> staking_data.serialize_to_bits()

  let assert "069cd82948650d902d95d52ea2ec91eae6deb0c9fe" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.AddStake(staker_address)) =
    staking_data.deserialize_all(serialized)

  should.equal(staker_address, address)
}

pub fn update_staker_serialization_test() {
  let assert Ok(Ok(signature_proof)) =
    bit_array.base16_decode(
      "007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500142b674b7b46fa751f91e35c16122356b98d48ea9ed6dfdebe6710ca18969825197e30d4a3dcaa7e3d3a03f25b99503ab58d7ebe582903f44fca46426e95f90b",
    )
    |> result.map(signature_proof.deserialize_all)

  let serialized =
    staking_data.UpdateStaker(None, False, signature_proof)
    |> staking_data.serialize_to_bits()

  let assert "070000007f07b8a4c2f6c2f7cb56584a00672af88733cb6f80f5d6e6cf4043a3d4aeec0500142b674b7b46fa751f91e35c16122356b98d48ea9ed6dfdebe6710ca18969825197e30d4a3dcaa7e3d3a03f25b99503ab58d7ebe582903f44fca46426e95f90b" =
    serialized |> misc.to_hex()

  let assert Ok(staking_data.UpdateStaker(
    new_delegation,
    reactivate_all_stake,
    proof,
  )) = staking_data.deserialize_all(serialized)

  should.equal(new_delegation, None)
  should.equal(reactivate_all_stake, False)
  should.equal(proof, signature_proof)
}
// pub fn set_active_stake_serialization_test() {
//   todo
// }

// pub fn retire_stake_serialization_test() {
//   todo
// }
