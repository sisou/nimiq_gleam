mod account;
mod trie_node;

use account::serialize_basic_account;
use trie_node::{hash_trie_node, serialize_trie_node};

fn main() {
    serialize_basic_account();
    serialize_trie_node();
    hash_trie_node();
}
