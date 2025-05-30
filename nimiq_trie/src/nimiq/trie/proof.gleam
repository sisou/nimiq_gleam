import nimiq/trie/proof_node.{type TrieProofNode}

pub type TrieProof {
  TrieProof(
    nodes: List(TrieProofNode),
    // missing_proven_by: Dict(KeyNibbles, KeyNibbles),
  )
}
