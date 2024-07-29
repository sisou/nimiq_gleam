import address
import argv
import gleam/io

pub fn main() {
  case argv.load().arguments {
    ["address", str] -> format_address(str)
    _ -> io.println("Usage: nimiq_gleam address <address>")
  }
}

fn format_address(str) {
  case address.from_string(str) {
    Ok(addr) -> io.println(address.to_user_friendly_address(addr))
    Error(err) -> io.println_error("ERROR: " <> err)
  }
}
