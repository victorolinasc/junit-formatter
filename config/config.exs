use Mix.Config

config :junit_formatter, report_file: "report_file_test.xml"

if Mix.env() == :test, do: import_config("#{Mix.env()}.exs")
