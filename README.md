JUnit Output for ExUnit
=========

**Work in progress**

A simple ExUnit Formatter that collects test results and generates an xml report in JUnit format. This is intended to be used by tools that can produce a graphical report, mainly targeted at Jenkins and its support for JUnit.

The report is generated in _build/test folder with a default filename of test-junit-report.xml. It can be configured through application configuration on the key report_file (application junit_formatter).

Pictures and code examples will be added in a future release.

## Usage

Add `JUnitFormatter` to your `ExUnit` configuration in `test/test_helper.exs` file. It should look like this:

```
ExUnit.configure formatters: [JUnitFormatter]
ExUnit.start
```

If you want to keep using the default formatter alongside the `JUnitFormatter` your `test/test_helper.exs` file should look like this:

```
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

```
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
