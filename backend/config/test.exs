import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
System.put_env("DATABASE_URL", "postgresql://postgres:postgres@localhost/azimutt_test#{System.get_env("MIX_TEST_PARTITION")}")

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :azimutt, AzimuttWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "dzev5qwQsHCg3zCMWwtwN4w0BdfkiEnWH21Tn8tGM7PmQNTKRkGp2RuHKbOQgLTt",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
