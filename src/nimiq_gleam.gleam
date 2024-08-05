import argv
import cli/address_command
import cli/transaction_command
import glint

pub fn main() {
  // Create a new glint instance
  glint.new()
  // With an app name which is used when printing help text
  |> glint.with_name("nimiq_gleam")
  // With pretty help enabled, using the built-in colours
  |> glint.pretty_help(glint.default_pretty_help())
  // With subcommands
  |> glint.add(at: ["address"], do: address_command.run())
  |> glint.add(at: ["tx"], do: transaction_command.run())
  // Execute with the arguments from stdin
  |> glint.run(argv.load().arguments)
}
