defmodule Vlf.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.0.2",
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
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
      # For tests
      {:credo, "~> 0.9.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8", only: :test}
    ]
  end

  defp aliases do
    [
      "deploy.prod": ["edeliver update production --start-deploy", "edeliver migrate production"],
    ]
  end  
end
