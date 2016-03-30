defmodule Formatter.Mixfile do
  use Mix.Project

  @version "1.0.1"
  
  def project do
    [app: :junit_formatter,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     package: package,
     consolidate_protocols: Mix.env != :test,
     description: description,
     name: "JUnit Formatter",
     test_coverage: [tool: ExCoveralls],
     docs: [extras: ["README.md": [title: "Overview", path: "overview"],
                     "CHANGELOG.md": [title: "Changelog"]],
            main: "overview",
						source_ref: "v#{@version}",
            source_url: "https://github.com/victorolinasc/junit-formatter"]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 0.2", only: :docs},
      {:ex_doc, "~> 0.11", only: :docs},
      {:excoveralls, "~> 0.5", only: :test},
      {:credo, "~> 0.3", only: [:dev, :test]}
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
