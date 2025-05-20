pub fn unwrap(res: Result(ok, err)) -> ok {
  case res {
    Ok(ok) -> ok
    Error(err) -> {
      echo err
      panic as "Panicked at unwrapping an error result"
    }
  }
}
