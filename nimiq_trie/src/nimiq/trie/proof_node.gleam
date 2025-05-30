import gleam/option.{type Option}

import iv

import nimiq/trie/key_nibbles.{type KeyNibbles}
import nimiq/trie/node_child.{type TrieNodeChild}

pub type ProofValue {
  None
  LeafValue(BitArray)
  HybridHash(BitArray)
  HybridValue(BitArray)
}

pub type TrieProofNode {
  TrieProofNode(
    key: KeyNibbles,
    value: ProofValue,
    children: iv.Array(Option(TrieNodeChild)),
  )
}
