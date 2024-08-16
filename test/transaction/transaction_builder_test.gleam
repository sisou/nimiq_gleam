import account/address.{type Address}
import coin.{Coin}
import gleam/bit_array
import gleam/option.{Some}
import gleeunit/should
import key/ed25519/private_key as ed25519_private_key
import key/ed25519/public_key as ed25519_public_key
import key/ed25519/signature as ed25519_signature
import key/public_key.{EdDsaPublicKey}
import key/signature.{EdDsaSignature}
import policy
import transaction/network_id
import transaction/signature_proof
import transaction/transaction.{type Transaction}
import transaction/transaction_builder

const validator_address = "83fa05dbe31f85e719f4c4fd67ebdba2e444d9f8"

const validator_private_key = "d0fbb3690f5308f457e245a3cc65ae8d6945155eadcac60d489ffc5583a60b9b"

const validator_signing_key = "b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a844"

const validator_signing_secret_key = "84c961b11b52a8244ffc5e9d0965bc2dfa6764970f8e4989d45901de401baf27"

const validator_voting_key = "713c60858b5c72adcf8b72b4dbea959d042769dcc93a0190e4b8aec92283548138833950aa214d920c17d3d19de27f6176d9fb21620edae76ad398670e17d5eba2f494b9b6901d457592ea68f9d35380c857ba44856ae037aff272ad6c1900442b426dde0bc53431e9ce5807f7ec4a05e71ce4a1e7e7b2511891521c4d3fd975764e3031ef646d48fa881ad88240813d40e533788f0dac2bc4d4c25db7b108c67dd28b7ec4c240cdc044badcaed7860a5d3da42ef860ed25a6db9c07be000a7f504f6d1b24ac81642206d5996b20749a156d7b39f851e60f228b19eef3fb3547469f03fc9764f5f68bc88e187ffee0f43f169acde847c78ea88029cdb19b91dd9562d60b607dd0347d67a0e33286c8908e4e9579a42685da95f06a9201"

// const validator_voting_secret_key = "65100f4aa301ded3d9868c3d76052dd0dfede426b51af371dcd8a4a076f11651c86286d2891063ce7b78217a6e163f38ebfde7eb9dcbf5927b2278b00d77329141d44f070620dd6b995455a6cdfe8eee03f657ff255cfb8fb3460ce1135701"

const validator_proof_of_knowledge = "b7561c15e53da2c482bfafddbf404f28b14ee2743e5cfe451c860da378b2ac23a651b574183d1287e2cea109943a34c44a7df9eb2fe5067c70f1c02bde900828c232a3d7736a278e0e8ac679bc2a1669f660c3810980526b7890f6e1708381"

const staker_address = "8c551fabc6e6e00c609c3f0313257ad7e835643c"

const staker_private_key = "62f21a296f00562c43999094587d02c0001676ddbd3f0acf9318efbcad0c8b43"

pub fn create_validator_transaction_test() {
  let assert Ok(signing_public_key) =
    ed25519_public_key.from_string(validator_signing_key)
  let assert Ok(voting_public_key) =
    bit_array.base16_decode(validator_voting_key)
  let assert Ok(reward_address) =
    address.from_hash(<<
      0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
      0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    >>)
  let assert Ok(signal_data) =
    bit_array.base16_decode(
      "0000000000000000000000000000000000000000000000000000000000000000",
    )
  let assert Ok(bls_proof_of_knowledge) =
    bit_array.base16_decode(validator_proof_of_knowledge)

  let tx =
    transaction_builder.new_create_validator(
      sender(),
      signing_public_key,
      voting_public_key,
      bls_proof_of_knowledge,
      reward_address,
      Some(signal_data),
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_inner(validator_private_key)
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c0000000000000000000000000000000000000000000103b40400b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a844713c60858b5c72adcf8b72b4dbea959d042769dcc93a0190e4b8aec92283548138833950aa214d920c17d3d19de27f6176d9fb21620edae76ad398670e17d5eba2f494b9b6901d457592ea68f9d35380c857ba44856ae037aff272ad6c1900442b426dde0bc53431e9ce5807f7ec4a05e71ce4a1e7e7b2511891521c4d3fd975764e3031ef646d48fa881ad88240813d40e533788f0dac2bc4d4c25db7b108c67dd28b7ec4c240cdc044badcaed7860a5d3da42ef860ed25a6db9c07be000a7f504f6d1b24ac81642206d5996b20749a156d7b39f851e60f228b19eef3fb3547469f03fc9764f5f68bc88e187ffee0f43f169acde847c78ea88029cdb19b91dd9562d60b607dd0347d67a0e33286c8908e4e9579a42685da95f06a92010303030303030303030303030303030303030303010000000000000000000000000000000000000000000000000000000000000000b7561c15e53da2c482bfafddbf404f28b14ee2743e5cfe451c860da378b2ac23a651b574183d1287e2cea109943a34c44a7df9eb2fe5067c70f1c02bde900828c232a3d7736a278e0e8ac679bc2a1669f660c3810980526b7890f6e1708381007451b039e2f3fcafc3be7c6bd9e01fbc072c956a2b95a335cfb3cd3702335b530079dbb852cfc6b9571b4bbed6f0f302d8f1deef55640998c2145b56aed007fc1b92222a2778ed3b562f59b23570e6fd1dfb7af07cf08cd6e58f401aa7dba7c70d00000002540be40000000000000000640000000107006200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd910500614003ac99ddcb92b8af398ff1b554d3b664f033a27b04fe9d265ac426d1fde1b2ea9fbee26bf0c8e62b89f273a984806d79de67e836c9fcec3455639b58480a",
  ))
}

pub fn update_validator_transaction_test() {
  let assert Ok(signing_public_key) =
    ed25519_public_key.from_string(validator_signing_key)
  let assert Ok(voting_public_key) =
    bit_array.base16_decode(validator_voting_key)
  let assert Ok(reward_address) =
    address.from_hash(<<
      0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
      0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
    >>)
  let assert Ok(signal_data) =
    bit_array.base16_decode(
      "0000000000000000000000000000000000000000000000000000000000000000",
    )
  let assert Ok(bls_proof_of_knowledge) =
    bit_array.base16_decode(validator_proof_of_knowledge)

  let tx =
    transaction_builder.new_update_validator(
      sender(),
      Some(signing_public_key),
      Some(voting_public_key),
      Some(bls_proof_of_knowledge),
      Some(reward_address),
      Some(Some(signal_data)),
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_inner(validator_private_key)
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c0000000000000000000000000000000000000000000103b9040101b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a84401713c60858b5c72adcf8b72b4dbea959d042769dcc93a0190e4b8aec92283548138833950aa214d920c17d3d19de27f6176d9fb21620edae76ad398670e17d5eba2f494b9b6901d457592ea68f9d35380c857ba44856ae037aff272ad6c1900442b426dde0bc53431e9ce5807f7ec4a05e71ce4a1e7e7b2511891521c4d3fd975764e3031ef646d48fa881ad88240813d40e533788f0dac2bc4d4c25db7b108c67dd28b7ec4c240cdc044badcaed7860a5d3da42ef860ed25a6db9c07be000a7f504f6d1b24ac81642206d5996b20749a156d7b39f851e60f228b19eef3fb3547469f03fc9764f5f68bc88e187ffee0f43f169acde847c78ea88029cdb19b91dd9562d60b607dd0347d67a0e33286c8908e4e9579a42685da95f06a92010103030303030303030303030303030303030303030101000000000000000000000000000000000000000000000000000000000000000001b7561c15e53da2c482bfafddbf404f28b14ee2743e5cfe451c860da378b2ac23a651b574183d1287e2cea109943a34c44a7df9eb2fe5067c70f1c02bde900828c232a3d7736a278e0e8ac679bc2a1669f660c3810980526b7890f6e1708381007451b039e2f3fcafc3be7c6bd9e01fbc072c956a2b95a335cfb3cd3702335b5300ff327a38d36a5a3aa0052a3c761fd4f820b4289f19522a299004c747676e364522b24317a332bd65f9dcee8a207e7ef5096f7a09c15155a9f3159ca623226306000000000000000000000000000000640000000107026200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd910500da1106e3cc1137a33b7a34101d6a15ad12357280b5d8e1de39702f2890e9f0d597f2e14b2f0e5b45dd6f5fbe9a3e9112b8d3463f1fdd79f77a468386ff916b0a",
  ))
}

pub fn deactivate_validator_transaction_test() {
  let assert Ok(validator_address) = address.from_string(validator_address)

  let tx =
    transaction_builder.new_deactivate_validator(
      sender(),
      validator_address,
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_inner(validator_signing_secret_key)
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c0000000000000000000000000000000000000000000103770283fa05dbe31f85e719f4c4fd67ebdba2e444d9f800b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a84400ba13522884a716f0688ceeeaabf37e91cbee9798d05ff5f03d3eb2f0ff280f20f83c1327d1f2a908fcecebdfa194283150dde38627c0b91e2c5175c2bef98102000000000000000000000000000000640000000107026200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd910500cc3d26a7c19aca652c22aadb2fee3f104b35dff438d4a4ae3d46f44e762027c3fad96ed24a35460d14be9c5a17eb9b120560ce58a002724ccc2b9dd49c6d510c",
  ))
}

pub fn reactivate_validator_transaction_test() {
  let assert Ok(validator_address) = address.from_string(validator_address)

  let tx =
    transaction_builder.new_reactivate_validator(
      sender(),
      validator_address,
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_inner(validator_signing_secret_key)
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c0000000000000000000000000000000000000000000103770383fa05dbe31f85e719f4c4fd67ebdba2e444d9f800b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a844005fe2ead749549fb7d329ef9f99bf5693c87977fd3253400581a8b832d2bef6a705d6fe76ba1e875ade5f0185396cde41622497a9761959adf7ccfca99bcfff07000000000000000000000000000000640000000107026200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd91050000f1a9c7bc1883df69d8dab50661ea56a22b64764b0206fef6f533a47504d924c6574f493f591519ea633e5c7a24fa79f13384d571e5c466c6ca7b0fe8b3100f",
  ))
}

pub fn retire_validator_transaction_test() {
  let tx =
    transaction_builder.new_retire_validator(
      sender(),
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_inner(validator_signing_secret_key)
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c0000000000000000000000000000000000000000000103630400b300481ddd7af6be3cf5c123b7af2c21f87f4ac808c8b0e622eb85826124a84400fd7e470f62d7d89158109c0440c2815a6829a962ee838b02fb69840a5b8e6b8b58fe830981328064a45053b28b9abe7ace71838f60c5881b3d352c02f2067908000000000000000000000000000000640000000107026200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd9105003a86c09bd9dc35a226f2444c4c5ce564fda1958571682aaf7548b210d41969c4b2c85b662f5769b9c5916e5abd3b841355fd011ae7b19b7553693621ba76f805",
  ))
}

pub fn delete_validator_transaction_test() {
  let recipient = sender()

  let tx =
    transaction_builder.new_delete_validator(
      recipient,
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_outer_with_key(validator_private_key)
  |> transaction.to_hex()
  |> should.equal(Ok(
    "0100000000000000000000000000000000000000010301008c551fabc6e6e00c609c3f0313257ad7e835643c000000000002540be39c000000000000006400000001070062007451b039e2f3fcafc3be7c6bd9e01fbc072c956a2b95a335cfb3cd3702335b53001450cfe0a974b19c7564411fa9d075d28170a76a8f9f40158be8fa86bfd391e389a7f49e243680947006569dff74dcc09721dd861b8977cf66343a4c6c9fab06",
  ))
}

pub fn create_staker_transaction_test() {
  let assert Ok(delegation) = address.from_string(validator_address)

  let tx =
    transaction_builder.new_create_staker(
      sender(),
      Some(delegation),
      policy.minimum_stake,
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_inner(staker_private_key)
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c000000000000000000000000000000000000000000010378050183fa05dbe31f85e719f4c4fd67ebdba2e444d9f800b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd91050078848bb51c29e0cfa5ef76c851f65366dc788e9f9b8c1cba28972eb9aaa4a2464bb43262985ef0703568865f765460a83e8694b25665f0bc249de3096464df0b000000000098968000000000000000640000000107006200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd91050032e29c914094d23a4ce65921041227208820b24551b97e72703c8bcc8f3084ba4680e9e8fd926462f021c4a54dce5f864ba2112ba032afcb68a82935cc402503",
  ))
}

pub fn add_stake_transaction_test() {
  let assert Ok(staker_address) = address.from_string(staker_address)

  let tx =
    transaction_builder.new_add_stake(
      sender(),
      staker_address,
      Coin(100),
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c000000000000000000000000000000000000000000010315068c551fabc6e6e00c609c3f0313257ad7e835643c000000000000006400000000000000640000000107006200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd910500f5d801f531117483118108b30cd606301a424ba63147f3f0a2e085bd655fd15c8eafb971a39883fc9da3711d7ac474cd6047eed7791ec6e00c6ed1a464fddb01",
  ))
}

pub fn update_staker_transaction_test() {
  let assert Ok(delegation) = address.from_string(validator_address)

  let tx =
    transaction_builder.new_update_staker(
      sender(),
      Some(delegation),
      False,
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_inner(staker_private_key)
  |> sign_outer()
  |> transaction.to_hex()
  |> should.equal(Ok(
    "018c551fabc6e6e00c609c3f0313257ad7e835643c000000000000000000000000000000000000000000010379070183fa05dbe31f85e719f4c4fd67ebdba2e444d9f80000b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd91050086b3e9305b69d7228967569082a4b870c9dea0ea5e83c4e1f2866f492bc2c974ecc92ea595e23825b3ea7846a85af397c38c32689c3e38c5de244845a2f68b0b000000000000000000000000000000640000000107026200b3adb13fe6887f6cdcb8c82c429f718fcdbbb27b2a19df7c1ea9814f19cd910500aad587075d132f1b28335360fa5fed46c9fafd56119606981891cf7f9eec58dcdaebb55bb52a253e9c0cc5e14bb83977b99f4a15f15f48ecce8399796c618606",
  ))
}

pub fn remove_staker_transaction_test() {
  let recipient = sender()

  let tx =
    transaction_builder.new_remove_stake(
      recipient,
      Coin(1000),
      Coin(100),
      1,
      network_id.UnitAlbatross,
    )

  tx
  |> sign_outer_with_key(validator_private_key)
  |> transaction.to_hex()
  |> should.equal(Ok(
    "0100000000000000000000000000000000000000010301018c551fabc6e6e00c609c3f0313257ad7e835643c000000000000000003e8000000000000006400000001070062007451b039e2f3fcafc3be7c6bd9e01fbc072c956a2b95a335cfb3cd3702335b5300cdb476051adbdb069a880d475aefc327f91e760abd588317bc801b2b17292e26197bfb980afcd3d3351d21a48c5e6edd00a215cff9d4bd9b881099b4749ee100",
  ))
}

fn sender() -> Address {
  let assert Ok(staker_address) = address.from_string(staker_address)
  staker_address
}

fn sign_inner(
  tx: transaction_builder.InternallyUnsignedTransaction,
  secret_key: String,
) -> Transaction {
  let assert Ok(private_key) = ed25519_private_key.from_string(secret_key)
  let public_key = ed25519_public_key.derive_key(private_key)
  let signature =
    ed25519_signature.create(
      private_key,
      public_key,
      transaction_builder.serialize_content(tx),
    )
  let proof =
    signature_proof.single_sig(
      EdDsaPublicKey(public_key),
      EdDsaSignature(signature),
    )

  tx |> transaction_builder.set_internal_proof(proof)
}

fn sign_outer(tx: Transaction) -> Transaction {
  let assert Ok(staker_private_key) =
    ed25519_private_key.from_string(staker_private_key)
  let staker_public_key = ed25519_public_key.derive_key(staker_private_key)
  let signature =
    ed25519_signature.create(
      staker_private_key,
      staker_public_key,
      transaction.serialize_content(tx),
    )
  let proof =
    signature_proof.single_sig(
      EdDsaPublicKey(staker_public_key),
      EdDsaSignature(signature),
    )

  tx |> transaction.set_proof(signature_proof.serialize_to_bits(proof))
}

fn sign_outer_with_key(tx: Transaction, secret_key: String) -> Transaction {
  let assert Ok(private_key) = ed25519_private_key.from_string(secret_key)
  let public_key = ed25519_public_key.derive_key(private_key)
  let signature =
    ed25519_signature.create(
      private_key,
      public_key,
      transaction.serialize_content(tx),
    )
  let proof =
    signature_proof.single_sig(
      EdDsaPublicKey(public_key),
      EdDsaSignature(signature),
    )

  tx |> transaction.set_proof(signature_proof.serialize_to_bits(proof))
}
