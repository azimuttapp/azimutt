defmodule Azimutt.MixProject do
  use Mix.Project

  def project do
    [
      app: :azimutt,
      version: "2.0.#{DateTime.to_unix(DateTime.utc_now())}",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # Docs
      name: "Azimutt",
      source_url: "https://github.com/azimuttapp/azimutt",
      homepage_url: "https://azimutt.app",
      docs: [
        # The main page in the docs
        main: "Azimutt",
        logo: "priv/static/images/logo_dark.svg",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Azimutt.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.6.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.11"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.7"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:yaml_elixir, "~> 2.8.0"},
      {:earmark, ">= 1.4.30"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:sentry, "~> 8.0"},
      {:hackney, "~> 1.18"},
      {:ueberauth, "~> 0.7"},
      {:ueberauth_github, "~> 0.8.1"},
      {:faker, "~> 0.17"},
      {:timex, "~> 3.7"},
      {:stripity_stripe, "~> 2.15"},
      {:gen_smtp, "~> 1.2"},
      {:phx_live_storybook, "~> 0.3.0"},
      {:phoenix_swagger, "~> 0.8.3"},
      {:ex_json_schema, "~> 0.5"},
      {:typed_struct, "~> 0.3.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0"},
      {:cors_plug, "~> 3.0"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.3"},
      {:sweet_xml, "~> 0.7.3"},
      {:httpoison, "~> 1.8"},
      {:html_entities, "~> 0.5"},
      {:oauther, "~> 1.3"},
      {:extwitter, "~> 0.14"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      seeds: "run priv/repo/seeds.exs",
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "esbuild default --minify",
        "tailwind default --minify",
        "phx.digest"
      ],
      elm: ["cmd --cd ../frontend npm run make"],
      "elm.server": ["cmd --cd ../frontend npm run server"],
      "elm.build": ["cmd --cd ../frontend npm run build"],
      "elm.book": ["cmd --cd ../frontend npm run book"],
      "elm.review": ["cmd --cd ../frontend elm-review"],
      "elm.test": ["cmd --cd ../frontend elm-test"],
      "ts.test": ["cmd --cd ../frontend npm run test"],
      swagger: ["phx.swagger.generate priv/static/swagger.json"]
    ]
  end
end
