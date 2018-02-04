defmodule ExLoader.MixProject do
  use Mix.Project

  @version File.cwd!() |> Path.join("version") |> File.read!() |> String.trim()

  def project do
    [
      app: :ex_loader,
      version: @version,
      elixir: "~> 1.6",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # exdocs
      # Docs
      name: "ExLoader",
      source_url: "https://github.com/tubitv/ex_loader",
      homepage_url: "https://github.com/tubitv/ex_loader",
      docs: [
        main: "ExLoader",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nanoid, "~> 1.0.1"},
      # dev & test
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:ex_doc, "~> 0.18", only: [:dev, :test]},
      {:httpoison, "~> 1.0", only: [:test]},
      {:jason, "~> 1.0", onbly: [:test]},
      {:pre_commit_hook, "~> 1.2", only: [:dev]}
    ]
  end

  defp description do
    """
    Load a single beam file, an app (a set of beams), or an erlang release (a set of apps) to a node.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "version"],
      licenses: ["MIT"],
      maintainers: ["tyr.chen@gmail.com"],
      links: %{
        "GitHub" => "https://github.com/tubitv/ex_loader",
        "Docs" => "https://hexdocs.pm/ex_loader"
      }
    ]
  end
end
