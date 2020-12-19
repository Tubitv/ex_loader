defmodule ExampleComplexApp.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        example_complex_app: [
          applications: [app1: :permanent, app2: :permanent],
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:distillery, "~> 1.5.2"},
      {:ex_statsd, ">= 0.5.1"},
      {:poison, "~> 3.0"},
      {:timex, "~> 3.1"},
      {:flow, "~> 0.12"},
      {:recon, "~> 2.3.2"},
      {:recon_ex, "~> 0.9.1"},
      {:observer_cli, "~> 1.2.1"},

      {:benchee, "~> 0.9.0", only: [:dev, :test]}
    ]
  end
end
