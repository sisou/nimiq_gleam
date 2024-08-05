/// For when you really know the Result cannot be Error
pub fn unwrap(res: Result(a, _)) -> a {
  case res {
    Ok(a) -> a
    Error(_) -> panic as "Called unwrap on an Error value"
  }
}
