JUnitFormatter
=========

[![Build Status](https://travis-ci.org/victorolinasc/junit-formatter.svg)](https://travis-ci.org/victorolinasc/junit-formatter)  [![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/junit_formatter/)  [![Downloads](https://img.shields.io/hexpm/dt/junit_formatter.svg)](https://hex.pm/packages/junit_formatter)  [![Coverage Status](https://coveralls.io/repos/github/victorolinasc/junit-formatter/badge.svg?branch=master)](https://coveralls.io/github/victorolinasc/junit-formatter?branch=master)

A simple ExUnit Formatter that collects test results and generates an xml report in JUnit format. This is intended to be used by tools that can produce a graphical report, mainly targeted at Jenkins and its support for JUnit.

The report is generated in `Mix.Project.app_path` folder with a default filename of test-junit-report.xml. It can be configured through application configuration on the key report_file (application junit_formatter).

> Versions 3+ require minimum Elixir version to be 1.5+. For older releases, please use version 2.2 of this library.

## Usage

First, add `JUnitFormatter` to the dependencies in your mix.exs:

```elixir
  defp deps do
    [
      {:junit_formatter, "~> 3.1", only: [:test]}
    ]
  end
```

Next, add `JUnitFormatter` to your `ExUnit` configuration in `test/test_helper.exs` file. It should look like this:


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
....

Finished in 0.1 seconds (0.07s on load, 0.08s on tests)
4 tests, 0 failures

Randomized with seed 600810
```

The JUnit style XML report for this project looks like this:

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

`JUnitFormatter` accepts 4 options that can be passed in config.exs (or equivalent environment configuration for tests):

- `print_report_file` (boolean - default `false`): tells formatter if you want to see the path where the file is being written to in the console. This might help you debug where the file is. By default it writes the report to the `Mix.Project.app_path` folder. This ensures compatibility with umbrella apps.
- `report_file` (binary - default `"test-junit-report.xml"`): the name of the file to write to. It must contain the extension. 99% of the time you will want the extension to be `.xml`, but if you don't you can pass any extension (though the contents of the file will be an xml document).
- `report_dir` (binary - default `Mix.Project.app_path()`): the directory to which the formatter will write the report. Do not end it with a slash. **IMPORTANT!!** `JUnitFormatter` will **NOT** create the directory. If you are pointing to a directory that is outside _build then it is your duty to clean it and to be sure it exists.
- `prepend_project_name?` (boolean - default `false`): tells if the report file should have the name of the project as a prefix. See the "Umbrella" part of the documentation.
- `include_filename?` (boolean - default `false`): dictates whether `<testcase>`s in the XML report should include a "file" attribute of the relative path to the file of the test. Note that this defaults to false because not all JUnit ingesters will accept a file attribute.  

Example configuration:

``` elixir
config :junit_formatter,
  report_file: "report_file_test.xml",
  report_dir: "/tmp",
  print_report_file: true,
  prepend_project_name?: true,
  include_filename?: true
```

This would generate the report at: `/tmp/myapp-report_file_test.xml`.

## Umbrella projects

`JUnitFormatter` works with umbrella projects too. By default, it will generate the xml report on each sub-project build folder. So, as an example, if you have two apps (`my-app` and `another`) it will generate the following reports:

- `_build/test/lib/my_app/report_file.xml`
- `_build/test/lib/another/report_file.xml`

This works without any extra configuration. There are times, though, where you want to customize the directory where the reports are generated. Let's say you add this configuration:

``` elixir
config :junit_formatter,
  report_dir: "/tmp"
```

Then, while running in an umbrela project, the first sub-project will run and generate a report file the following path:

- `/tmp/report_file.xml`

The next one will do the same **OVERRIDING** the first one. So, in order to avoid this, you can use the configuration option `prepend_project_name?` so that the result would be:

- `/tmp/my_app-report_file.xml`
- `/tmp/another-report_file.xml`

## Integrating on CI systems

Most CIs have a way for uploading test reports. This is a nice way to understand what failed on your build. Most of them use the JUnit report file format to provide this feature.

- [CircleCI](https://circleci.com/docs/2.0/language-elixir/) example configuration provides JUnit reports integration


## LICENSE

This project is available under Apache Public License version 2.0. See [LICENSE](https://github.com/victorolinasc/junit-formatter/blob/master/LICENSE).
