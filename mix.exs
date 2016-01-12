defmodule Formatter.Mixfile do
  use Mix.Project

  @version "0.1.1"
  
  def project do
    [app: :junit_formatter,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     package: package,
     description: "An ExUnit.Formatter that produces an XML report of the tests run in the project _build dir.\n" <>
       "It is a good fit with Jenkins test reporting plugin, for example.",
     name: "JUnit Formatter",
     docs: [extras: [ "README.md"],
            main: "readme",
						source_ref: "#{@version}",
            source_url: "https://github.com/victorolinasc/junit-formatter"]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.11", only: :docs},
     {:inch_ex, only: :docs}]
  end

  defp package do
    %{licenses: ["Apache 2"],
      maintainers: ["Victor Olinasc"],
      links: %{"Github" => "https://github.com/victorolinasc/junit-formatter",
               "docs" => "http://hexdocs.pm/junit_formatter/"}}
  end
end
