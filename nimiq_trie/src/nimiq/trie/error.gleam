pub type TrieError {
  /// Prefix doesn't match node's key.
  WrongPrefix
  /// Tried to query the value of a branch node. Branch nodes don't have a value.
  BranchesHaveNoValue
  /// Tried to query a child that does not exist.
  ChildDoesNotExist
  /// Child is incomplete.
  ChildIsStump
  /// Tried to store a value at the root node.
  RootCantHaveValue
  /// Tree is already complete.
  TrieAlreadyComplete
  /// Chunk does not match tree state.
  NonMatchingChunk
  /// Root hash does not match expected hash after applying chunk.
  ChunkHashMismatch
  /// Chunk is invalid: {0}
  InvalidChunk(String)
  /// Trie is not complete
  IncompleteTrie
  /// Serialization error
  Serialization(String)
}
