mod account;
mod trie;
mod trie_node;

use account::serialize_basic_account;
use trie::serialize_trie;
use trie_node::{hash_trie_node, serialize_trie_node};

fn main() {
    serialize_basic_account();
    hash_trie_node();
    serialize_trie_node();
    serialize_trie();
}
