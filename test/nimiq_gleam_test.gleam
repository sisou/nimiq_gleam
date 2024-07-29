import address
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn format_address_test() {
  case address.from_string("0000000000000000000000000000000000000000") {
    Ok(addr) ->
      address.to_user_friendly_address(addr)
      |> should.equal("NQ07 0000 0000 0000 0000 0000 0000 0000 0000")
    Error(_) -> should.fail()
  }
}
