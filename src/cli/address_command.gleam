import account/address
import gleam/io
import glint
import glint/constraint

fn format_flag() -> glint.Flag(String) {
  glint.string_flag("format")
  |> glint.flag_default("user-friendly")
  |> glint.flag_constraint(
    ["user-friendly", "hex", "base64", "base64url"] |> constraint.one_of,
  )
  |> glint.flag_help(
    "Set the address format to convert to (user-friendly | hex | base64 | base64url). Default is user-friendly.",
  )
}

/// The glint command that will be executed
pub fn run() -> glint.Command(Nil) {
  // Set the help text for the command
  use <- glint.command_help("Converts an address to another format.")

  // Register flags with the command
  use format <- glint.flag(format_flag())

  // Start the body of the command
  // This is what will be executed when the command is run
  use _, args, flags <- glint.command()

  // We can assert here because the format flag has a default and will therefore always have a value
  let assert Ok(format) = format(flags)

  // Business logic of the command
  let address = case args {
    [address, ..] -> address.from_string(address)
    _ -> Error("No address provided")
  }

  case address {
    Ok(addr) ->
      case format {
        "user-friendly" -> address.to_user_friendly_address(addr)
        "hex" -> address.to_hex(addr)
        "base64" -> address.to_base64(addr)
        "base64url" -> address.to_base64_url(addr)
        _ -> panic as "Invalid format"
      }
    Error(msg) -> "Error: " <> msg
  }
  |> io.println
}
