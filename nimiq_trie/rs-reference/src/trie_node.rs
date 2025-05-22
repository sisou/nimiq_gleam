use nimiq_hash::{Blake2bHash, Hash};
use nimiq_primitives::key_nibbles::KeyNibbles;
use nimiq_primitives::trie::trie_node::TrieNode;
use nimiq_serde::Serialize;

pub fn hash_trie_node() {
    let key: KeyNibbles = "cfb986".parse().unwrap();

        // let leaf_node = TrieNode::new_leaf(key.clone(), vec![66]);
        let mut branch_node = TrieNode::new_empty(key);

        let child_key_1 = "cfb986f5a".parse().unwrap();
        branch_node
            .put_child(&child_key_1, "child_1".hash())
            .unwrap();

        let child_key_2 = "cfb986ab9".parse().unwrap();
        branch_node
            .put_child(&child_key_2, "child_2".hash())
            .unwrap();

        let child_key_3 = "cfb9860f6".parse().unwrap();
        branch_node
            .put_child(&child_key_3, "child_3".hash())
            .unwrap();

        let child_key_4 = "cfb986d50".parse().unwrap();
        branch_node
            .put_child(&child_key_4, "child_4".hash())
            .unwrap();

        println!("Branch node hash: {:?}", branch_node.hash::<Blake2bHash>());
}

pub fn serialize_trie_node() {
    let key: KeyNibbles = "cfb986".parse().unwrap();

        // let leaf_node = TrieNode::new_leaf(key.clone(), vec![66]);
        let mut branch_node = TrieNode::new_empty(key);

        let child_key_1 = "cfb986f5a".parse().unwrap();
        branch_node
            .put_child(&child_key_1, "child_1".hash())
            .unwrap();

        let child_key_2 = "cfb986ab9".parse().unwrap();
        branch_node
            .put_child(&child_key_2, "child_2".hash())
            .unwrap();

        let child_key_3 = "cfb9860f6".parse().unwrap();
        branch_node
            .put_child(&child_key_3, "child_3".hash())
            .unwrap();

        let child_key_4 = "cfb986d50".parse().unwrap();
        branch_node
            .put_child(&child_key_4, "child_4".hash())
            .unwrap();

        println!("Branch node: {:?}", hex::encode(branch_node.serialize_to_vec()));
}
