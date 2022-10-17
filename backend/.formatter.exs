[
  import_deps: [:ecto, :phoenix, :typed_struct],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"],
  # keep in sync with Credo.Check.Readability.MaxLineLength in .credo.exs
  line_length: 140
]
