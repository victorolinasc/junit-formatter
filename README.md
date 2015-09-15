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
