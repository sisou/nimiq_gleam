import gleam/option.{type Option}

import iv

import key_nibbles.{type KeyNibbles}
import trie/trie_node_child.{type TrieNodeChild}

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
