## v1.3.0

### Bugfixes:

  - Handle errors that have a message with value `nil` properly. Thanks to @PierrePIRONIN.
  - Fixed Elixir 1.4+ warnings. Thanks to @jwfearn.
  - Improved test coverage (added skip tests).

## v1.2.0

### Backwards incompatible:

  - This release raises the minimum Elixir version to 1.1 and is only tested with Erlang 18 and above.

### Features:

  - Added config property `report_dir`. This makes it possible to set absolute paths for the generated reports.
  - Added helper function `JUnitFormatter.get_report_file_path/0` that returns the final path of the report with the applied defaults and configurations.

## v1.1.0

### Backwards incompatible: 

  - This release has changed the location where the report is written to. 

### Features:

  - Changed implementation of logging report file location to use `Logger`. This is meant to be more helpful in configuring since it can be disabled in Logger level.

### Bugfixes:

  - Support for umbrella projects. Reports are written to `Mix.Project.app_path` instead of `Mix.Project.build_path`.

## v1.0.0

### Features:

  - `ExUnit.Formatter` implementation that prints an xml to the build directory.
  
### Bugfixes:

  - Correctly show time of testsuite in seconds rather than micro seconds (thanks to [@ibizaman](https://github.com/ibizaman))
  - Correctly handle errors with empty messages (thanks to [@Reimerei](https://github.com/Reimerei))
  - Fixed name of failed tests tag in xml (thanks to [@KronicDeth](https://github.com/KronicDeth))
  - Fixed compatibility with Elixir 1.2 (thanks to [@adrienmo](https://github.com/adrienmo))
