ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start(trace: "--trace" in System.argv(), timeout: 5_000)
