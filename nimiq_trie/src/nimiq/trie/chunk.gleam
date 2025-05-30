import gleam/option.{type Option}

import nimiq/trie/item.{type TrieItem}
import nimiq/trie/key_nibbles.{type KeyNibbles}
import nimiq/trie/proof.{type TrieProof}

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
