mod account;
mod trie;
mod trie_node;

use account::serialize_basic_account;
use trie::{get_put_remove_works, serialize_trie};
use trie_node::{hash_trie_node, serialize_trie_node, simple_leaf};

fn main() {
    serialize_basic_account();
    simple_leaf();
    hash_trie_node();
    serialize_trie_node();
    serialize_trie();
    get_put_remove_works();
}
