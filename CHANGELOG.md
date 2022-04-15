# Changelog

## [3.3.1] - 2021-05-29

### Added

-  Don't store logs for test cases to reduce memory usage (#47 thanks to @vorce)

## [3.3.0] - 2021-05-29

### Added

- Automatically creates report_dir (#44 thanks to @wingyplus)

### Fixes

- Make it work with Elixir 1.12 (#45 thanks to @irgendeinich)

## [3.2.0] - 2021-04-24

### Added

- Option to include line number in reports. Fixes #40. (#41 thanks to @icehaunter)

### Fixed

- Using `extra_applications` instead of `applications`
- Switched CI system
- Removed warnings in tests

## [3.1.0] - 2020-03-14

### Added

- If `include_filename?` attribute is true, add the relative path from … (#37 thanks to @danadaldos)

## [3.0.1] - 2019-07-11

### Fixed

- Converts String to utf8 charlist, instead of Unicode (#34 thank to @mrmstn)

## 3.0.0

### Breaking:

- JUnitFormatter now supports only Elixir 1.5+. If you need support for older versions, please use version 2.x.

### Added:

- Error messages now retain their whole format from standard ExUnit formatter (thanks to @hauleth)
- Refactored the tests to use xpath (thanks to @hauleth)
- Refactored the code base to be more modern (thanks to @hauleth)

### Bugfixes:

- Fixed options description in README
- Better CI integration: Credo, test tracing
- Updated deps (and docs)

## 2.2.0

### Bugfixes:

  - Fix Unicode characters in test names on OTP 20. It is important to notice that test names with Unicode characters that are not ASCII will **ONLY** work if running on OTP 20. Thanks to @sparta-developers
  - Add option of prepending the project name to the report file to avoid overriding the results when in umbrella project. README was also updated. Thanks to @axelson for bringing the issue.

## 2.1.0

### Bugfixes:

  - Fixes subprocess crashes. When a subprocess crashes it sends a {:EXIT, pid} message that can't be parsed by Atom.to_string/1. Thanks to @dmt !
  - Fixes running tests on Elixir 1.6.0-rc.0. `ExUnit.Server.cases_loaded()` got renamed to `ExUnit.Server.modules_loaded()`.

## 2.0.0

### Backwards incompatible:

  - This release raises the minimum Elixir version to 1.4. This is due to GenEvent handlers for ExUnit.Formatter being deprecated in Elixir 1.4.

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

  - `ExUnit.Formatter` implementation that prints an XML to the build directory.
  
### Bugfixes:

  - Correctly show time of testsuite in seconds rather than micro seconds (thanks to [@ibizaman](https://github.com/ibizaman))
  - Correctly handle errors with empty messages (thanks to [@Reimerei](https://github.com/Reimerei))
  - Fixed name of failed tests tag in XML (thanks to [@KronicDeth](https://github.com/KronicDeth))
  - Fixed compatibility with Elixir 1.2 (thanks to [@adrienmo](https://github.com/adrienmo))
