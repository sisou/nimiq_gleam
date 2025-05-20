use nimiq_account::{Account, BasicAccount};
use nimiq_database::declare_table;
use nimiq_database::mdbx::MdbxDatabase;
use nimiq_database::traits::Database;
use nimiq_keys::Address;
use nimiq_primitives::coin::Coin;
use nimiq_primitives::key_nibbles::KeyNibbles;
use nimiq_primitives::trie::trie_node::TrieNode;
use nimiq_trie::WriteTransactionProxy;
use nimiq_trie::trie::MerkleRadixTrie;

pub fn serialize_trie_node() {
    let account = Account::Basic(BasicAccount {
        balance: Coin::from_u64_unchecked(1e5 as u64),
    });

    declare_table!(TestTrie, "database", KeyNibbles => TrieNode);

    let key_1 = Address::from_user_friendly_address("NQ05 U1RF QJNH JCS1 RDQX 4M3Y 60KR K6CN 5LKC")
        .unwrap()
        .to_hex()
        .parse()
        .unwrap();
    // let key_2 = "413b39931".parse().unwrap();
    // let key_3 = "413b397fa".parse().unwrap();
    // let key_4 = "cfb986f5a".parse().unwrap();

    let env = MdbxDatabase::new_volatile(Default::default()).unwrap();
    let trie = MerkleRadixTrie::new(&env, TestTrie);
    let mut raw_txn = env.write_transaction();
    let mut txn: WriteTransactionProxy = (&mut raw_txn).into();

    // assert_eq!(trie.count_nodes(&txn), (0, 0, 0));

    trie.put(&mut txn, &key_1, account).expect("complete trie");
    // // assert_eq!(trie.count_nodes(&txn), (0, 0, 1));
    // trie.put(&mut txn, &key_2, 999).expect("complete trie");
    // // assert_eq!(trie.count_nodes(&txn), (1, 0, 2));
    // trie.put(&mut txn, &key_3, 1337).expect("complete trie");

    let hash = trie.root_hash(&txn).expect("complete trie");
    println!("Trie (1 account) hash: {}", hex::encode(hash)); // 8c83a162dbc67b9179a7bec49a6812bf475b74c4b6631236414d1b54c7e939a4

    let num_branches = trie.num_branches(&txn);
    println!("Trie (1 account) num branches: {}", num_branches); // 0
    let num_leaves = trie.num_leaves(&txn);
    println!("Trie (1 account) num leaves: {}", num_leaves); // 1
    let num_hybrids = trie.num_hybrids(&txn);
    println!("Trie (1 account) num hybrids: {}", num_hybrids); // 0

    trie.iter_nodes(
        &txn,
        &"0000000000000000000000000000000000000000".parse().unwrap(),
        &"ffffffffffffffffffffffffffffffffffffffff".parse().unwrap(),
    )
    .for_each(|node: Account| {
        println!("Trie node: {:?}", node);
    });

    // // assert_eq!(trie.count_nodes(&txn), (2, 0, 3));
    // assert_eq!(trie.get(&txn, &key_1).expect("complete trie"), Some(80085));
    // assert_eq!(trie.get(&txn, &key_2).expect("complete trie"), Some(999));
    // assert_eq!(trie.get(&txn, &key_3).expect("complete trie"), Some(1337));
    // assert_eq!(trie.get(&txn, &key_4).expect("complete trie"), None::<i32>);

    // trie.remove(&mut txn, &key_4);
    // // assert_eq!(trie.count_nodes(&txn), (2, 0, 3));
    // assert_eq!(trie.get(&txn, &key_1).expect("complete trie"), Some(80085));
    // assert_eq!(trie.get(&txn, &key_2).expect("complete trie"), Some(999));
    // assert_eq!(trie.get(&txn, &key_3).expect("complete trie"), Some(1337));

    // trie.remove(&mut txn, &key_1);
    // // assert_eq!(trie.count_nodes(&txn), (1, 0, 2));
    // assert_eq!(trie.get(&txn, &key_1).expect("complete trie"), None::<i32>);
    // assert_eq!(trie.get(&txn, &key_2).expect("complete trie"), Some(999));
    // assert_eq!(trie.get(&txn, &key_3).expect("complete trie"), Some(1337));

    // trie.remove(&mut txn, &key_2);
    // // assert_eq!(trie.count_nodes(&txn), (0, 0, 1));
    // assert_eq!(trie.get(&txn, &key_1).expect("complete trie"), None::<i32>);
    // assert_eq!(trie.get(&txn, &key_2).expect("complete trie"), None::<i32>);
    // assert_eq!(trie.get(&txn, &key_3).expect("complete trie"), Some(1337));

    // trie.remove(&mut txn, &key_3);
    // // assert_eq!(trie.count_nodes(&txn), (0, 0, 0));
    // assert_eq!(trie.get(&txn, &key_1).expect("complete trie"), None::<i32>);
    // assert_eq!(trie.get(&txn, &key_2).expect("complete trie"), None::<i32>);
    // assert_eq!(trie.get(&txn, &key_3).expect("complete trie"), None::<i32>);

    // trie.remove(&mut txn, &KeyNibbles::ROOT);
    // // assert_eq!(trie.count_nodes(&txn), (0, 0, 0));
    // assert_eq!(trie.get(&txn, &key_1).expect("complete trie"), None::<i32>);
    // assert_eq!(trie.get(&txn, &key_2).expect("complete trie"), None::<i32>);
    // assert_eq!(trie.get(&txn, &key_3).expect("complete trie"), None::<i32>);
}
