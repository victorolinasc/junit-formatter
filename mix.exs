defmodule Formatter.Mixfile do
  use Mix.Project

  @source_url "https://github.com/victorolinasc/junit-formatter"
  @version "3.3.1"

  def project do
    [
      app: :junit_formatter,
      version: @version,
      elixir: "~> 1.5",
      deps: deps(),
      package: package(),
      docs: docs(),
      consolidate_protocols: Mix.env() != :test,
      description: description(),
      name: "JUnit Formatter",
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [extra_applications: [:logger, :xmerl]]
  end

  defp deps do
    [
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:exjsx, "~> 4.0", only: :test, override: true},
      {:credo, "~> 1.6", only: [:dev, :test]},
      {:sweet_xml, "~> 0.7", only: :test}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      maintainers: ["Victor Nascimento"],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => @source_url <> "/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp description do
    """
    An ExUnit.Formatter that produces an XML report of the tests run in the project _build dir.
    It is a good fit with Jenkins test reporting plugin, for example.
    """
  end
end
