JUnitFormatter
=========

[![Build Status](https://travis-ci.org/victorolinasc/junit-formatter.svg)](https://travis-ci.org/victorolinasc/junit-formatter)  [![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/junit_formatter/)  [![Downloads](https://img.shields.io/hexpm/dt/junit_formatter.svg)](https://hex.pm/packages/junit_formatter)

A simple ExUnit Formatter that collects test results and generates an xml report in JUnit format. This is intended to be used by tools that can produce a graphical report, mainly targeted at Jenkins and its support for JUnit.

The report is generated in _build/test folder with a default filename of test-junit-report.xml. It can be configured through application configuration on the key report_file (application junit_formatter).

## Usage

Add `JUnitFormatter` to your `ExUnit` configuration in `test/test_helper.exs` file. It should look like this:


```elixir
ExUnit.configure formatters: [JUnitFormatter]
ExUnit.start
```


If you want to keep using the default formatter alongside the `JUnitFormatter` your `test/test_helper.exs` file should look like this:

```elixir
ExUnit.configure formatters: [JUnitFormatter, ExUnit.CLIFormatter]
ExUnit.start
```

Then run your tests like normal:

```
Compiled lib/formatter.ex
Generated junit_formatter app
....

Finished in 0.1 seconds (0.07s on load, 0.08s on tests)
4 tests, 0 failures

Randomized with seed 600810
```

Your JUnit style XML report will be written to `_build/test/test-junit-report.xml`.  The report for this project looks like this:

```xml
<?xml version="1.0"?>
<testsuites>
	<testsuite errors="0" failures="0" name="Elixir.FormatterTest" tests="4" time="82086">
		<testcase classname="Elixir.FormatterTest" name="test it counts raises as failures" time="16805"/>
		<testcase classname="Elixir.FormatterTest" name="test that an invalid test generates a proper report" time="16463"/>
		<testcase classname="Elixir.FormatterTest" name="test that a valid test generates a proper report" time="16328"/>
		<testcase classname="Elixir.FormatterTest" name="test valid and invalid tests generates a proper report" time="32490"/>
	</testsuite>
</testsuites>
```

*note: this example has been reformatted for readability.*

## Options

`JUnitFormatter` accepts 2 options that can be passed in config.exs (or equivalent environment configuration for tests):

- `print_report_file` (boolean - default `false`): tells formatter if you want to see the path where the file is being written to in the console (`IO.puts "Wrote JUnit report to: #{file_name}"`). This might help you debug where the file is.
- `report_file` (binary - default `"test-junit-report.xml"`): the name of the file to write to. It must contain the extension. 99% of the time you will want the extension to be `.xml`, but if you don't you can pass any extension (though the contents of the file will be an xml document). 

Example configuration: 

``` elixir
config :junit_formatter,
  report_file: "report_file_test.xml",
  print_report_file: true
```


