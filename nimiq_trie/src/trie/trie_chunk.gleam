import gleam/option.{type Option}

import key_nibbles.{type KeyNibbles}
import trie/trie_item.{type TrieItem}
import trie/trie_proof.{type TrieProof}

pub type TrieChunk {
  TrieChunk(
    end_key: Option(KeyNibbles),
    items: List(TrieItem),
    proof: TrieProof,
  )
}

pub type TrieChunkPushResult {
  /// The chunk was successfully applied.
  Applied
  /// Reflects the case when the start key does not match.
  Ignored
}
