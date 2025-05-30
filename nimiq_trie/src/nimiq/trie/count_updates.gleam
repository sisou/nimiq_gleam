import gleam/option.{type Option, None, Some}

import nimiq/trie/node.{type TrieNodeKind}
import nimiq/trie/root_data.{type RootData, RootData}

pub type CountUpdates {
  CountUpdates(branches: Int, hybrids: Int, leaves: Int)
}

pub fn default() -> CountUpdates {
  CountUpdates(branches: 0, hybrids: 0, leaves: 0)
}

pub fn from_update(
  prev: Option(TrieNodeKind),
  cur: Option(TrieNodeKind),
) -> CountUpdates {
  default() |> apply_update(prev, cur)
}

pub fn apply_update(
  update: CountUpdates,
  prev: Option(TrieNodeKind),
  cur: Option(TrieNodeKind),
) -> CountUpdates {
  let update = case prev {
    Some(kind) ->
      case kind {
        node.Root -> update
        node.Branch -> CountUpdates(..update, branches: update.branches - 1)
        node.Hybrid -> CountUpdates(..update, hybrids: update.hybrids - 1)
        node.Leaf -> CountUpdates(..update, leaves: update.leaves - 1)
      }
    None -> update
  }
  let update = case cur {
    Some(kind) ->
      case kind {
        node.Root -> update
        node.Branch -> CountUpdates(..update, branches: update.branches + 1)
        node.Hybrid -> CountUpdates(..update, hybrids: update.hybrids + 1)
        node.Leaf -> CountUpdates(..update, leaves: update.leaves + 1)
      }
    None -> update
  }
  update
}

pub fn is_empty(update: CountUpdates) -> Bool {
  update.branches == 0 && update.hybrids == 0 && update.leaves == 0
}

pub fn update_root_data(update: CountUpdates, root_data: RootData) -> RootData {
  RootData(
    num_branches: root_data.num_branches + update.branches,
    num_hybrids: root_data.num_hybrids + update.hybrids,
    num_leaves: root_data.num_leaves + update.leaves,
  )
}
