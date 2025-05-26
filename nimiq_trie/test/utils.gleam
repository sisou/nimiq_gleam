// TODO: Replace usage with let assert Ok(res)
pub fn unwrap(res: Result(ok, err)) -> ok {
  let assert Ok(res) = res as "Panicked at unwrapping an error result"
  res
}
