use nimiq_account::{Account, BasicAccount};
use nimiq_primitives::coin::Coin;
use nimiq_serde::Serialize;

pub fn serialize_basic_account() {
    let account = Account::Basic(BasicAccount {
        balance: Coin::from_u64_unchecked(1e5 as u64),
    });

    let serialized = account.serialize_to_vec();
    println!(
        "Basic account (1 NIM) serialized: {}",
        hex::encode(serialized)
    ); // 0000000000000186a0
}
