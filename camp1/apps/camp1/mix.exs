defmodule Camp1.MixProject do
  use Mix.Project

  def project do
    [
      app: :camp1,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Camp1.Application, []},
      extra_applications: [:logger, :runtime_tools, :faker_elixir_octopus]
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
      {:bcrypt_elixir, "~> 2.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.0"},
      {:faker_elixir_octopus, "~> 1.0.0",  only: [:dev, :test]},
      {:timex, "~> 3.6"},
      {:mogrify, "~> 0.7.2"},
      {:membrane_core, "~> 0.6.0"},
      {:rename, "~> 0.1.0", only: :dev},
      # {:membrane_element_udp, "~> 0.3.2"},
      # {:membrane_element_file, "~> 0.3.0"},
      # {:membrane_http_adaptive_stream_plugin, "~> 0.1.0"},
      # {:membrane_aac_format, "~> 0.1.0"},
      # {:membrane_rtp_aac_plugin, "~> 0.1.0-alpha"},
      # {:membrane_rtp_plugin, "~> 0.4.0-alpha"},
      # {:membrane_element_tee, "~> 0.3.2"},
      # {:membrane_element_fake, "~> 0.3"},
      # {:membrane_aac_plugin, "~> 0.5.1"},
      # {:membrane_opus_plugin, "~> 0.2.1"},
      {:membrane_opus_plugin, "~> 0.2.1"},
      {:membrane_file_plugin, "~> 0.5.0"},
      {:membrane_portaudio_plugin, "~> 0.5.1"},
      {:membrane_ffmpeg_swresample_plugin, "~> 0.5.0"},
      {:membrane_mp3_mad_plugin, "~> 0.5.0"},
      {:membrane_remote_stream_format, "~> 0.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
