defmodule Formatter.Mixfile do
  use Mix.Project

  @version "1.3.0"

  def project do
    [app: :junit_formatter,
     version: @version,
     elixir: "~> 1.1",
     deps: deps(),
     package: package(),
     consolidate_protocols: Mix.env != :test,
     description: description(),
     name: "JUnit Formatter",
     test_coverage: [tool: ExCoveralls],
     docs: [extras: ["README.md": [title: "Overview"],
                     "CHANGELOG.md": [title: "Changelog"]],
            main: "readme",
            source_ref: "v#{@version}",
            source_url: "https://github.com/victorolinasc/junit-formatter"]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 1.1", only: :docs},
      {:ex_doc, "~> 0.14", only: :docs},
      {:excoveralls, "~> 0.6", only: :test},
      {:exjsx, "~> 4.0", only: :test, override: true},
      {:credo, "~> 0.6", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "CHANGELOG*"],
      maintainers: ["Victor Nascimento"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/victorolinasc/junit-formatter",
               "docs" => "http://hexdocs.pm/junit_formatter/"}
    ]
  end

  defp description do
    """
    An ExUnit.Formatter that produces an XML report of the tests run in the project _build dir.
    It is a good fit with Jenkins test reporting plugin, for example.
    """
  end
end
