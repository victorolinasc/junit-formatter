defmodule JUnitFormatter do
  @moduledoc """
  * A ExUnit.Formatter implementation that generates a xml in the format understood by JUnit.

  To acomplish this, there are some mappings that are not straight one to one.
  Therefore, here goes the mapping:

  - JUnit - ExUnit
  - Testsuites - :testsuite
  - Testsuite - %ExUnit.TestCase{}
  - failures = failures
  - skipped = skip
  - errors = invalid
  - time = (sum of all times in seconds rounded down)
  - Testcase - %ExUnit.Test
  - name = :case
  - test = :test
  - content (only if not successful)
  - skipped = {:state, {:skip, _}}
  - failed = {:state, {:failed, {_, reason, stacktrace}}}
  - reason = reason.message
  - contet = Exception.format_stacktrace(stacktrace)
  - error = {:invalid, module}

  The report is written to a file in the _build directory.
  """
  require Record
  use GenServer

  # Needed to use :xmerl
  Record.defrecord(:xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl"))
  Record.defrecord(:xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))

  Record.defrecord(
    :xmlAttribute,
    Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  )

  defmodule TestCaseStats do
    @moduledoc """
    A struct to keep track of test values and tests themselves.

    It is used to build the testsuite junit node.
    """
    defstruct errors: 0,
              failures: 0,
              skipped: 0,
              tests: 0,
              time: 0,
              test_cases: []

    @type t :: %__MODULE__{
            errors: non_neg_integer,
            failures: non_neg_integer,
            skipped: non_neg_integer,
            tests: non_neg_integer,
            time: non_neg_integer,
            test_cases: [ExUnit.Test.t()]
          }
  end

  ## Formatter callbacks: may use opts in the future to configure file name pattern

  def init(_opts), do: {:ok, []}

  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    # do the real magic
    suites = Enum.map(config, &generate_testsuite_xml/1)
    # wrap result in a root node (not adding any attribute to root)
    result = :xmerl.export_simple([{:testsuites, [], suites}], :xmerl_xml)

    # save the report in an xml file
    file_name = get_report_file_path()
    file = File.open!(file_name, [:write])
    IO.write(file, result)
    File.close(file)

    if Application.get_env(:junit_formatter, :print_report_file, false) do
      require Logger
      Logger.debug(fn -> "Wrote JUnit report to: #{file_name}" end)
    end

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, config) do
    stats = adjust_case_stats(test, config)
    config = Keyword.put(config, test.case, stats)

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skip, _}} = test}, config) do
    stats = adjust_case_stats(test, config)
    stats = %{stats | skipped: stats.skipped + 1}
    config = Keyword.put(config, test.case, stats)

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, _failed}} = test}, config) do
    stats = adjust_case_stats(test, config)
    stats = %{stats | failures: stats.failures + 1}
    config = Keyword.put(config, test.case, stats)

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _module}} = test}, config) do
    stats = adjust_case_stats(test, config)
    stats = %{stats | errors: stats.errors + 1}
    config = Keyword.put(config, test.case, stats)

    {:noreply, config}
  end

  def handle_cast(_event, config) do
    {:noreply, config}
  end

  @doc "Formats time from nanos to seconds"
  @spec format_time(integer) :: integer
  def format_time(time), do: time |> us_to_ms |> format_ms

  @doc """
  Helper function to get the full path of the generated report file.
  It can be passed 2 configurations
  - report_dir: full path of a directory (defaults to `Mix.Project.app_path()`)
  - report_file: name of the generated file (defaults to "test-junit-report.xml")
  """
  @spec get_report_file_path() :: String.t()
  def get_report_file_path() do
    prepend = Application.get_env(:junit_formatter, :prepend_project_name?, false)

    report_file = Application.get_env(:junit_formatter, :report_file, "test-junit-report.xml")
    report_dir = Application.get_env(:junit_formatter, :report_dir, Mix.Project.app_path())

    if prepend do
      "#{report_dir}/#{Mix.Project.config()[:app]}-#{report_file}"
    else
      "#{report_dir}/#{report_file}"
    end
  end

  # PRIVATE ------------

  defp adjust_case_stats(%ExUnit.Test{} = test, config) do
    stats = Keyword.get(config, test.case, %JUnitFormatter.TestCaseStats{})
    stats = %{stats | tests: stats.tests + 1}
    stats = %{stats | time: stats.time + test.time}
    %{stats | test_cases: [test | stats.test_cases]}
  end

  defp generate_testsuite_xml({name, %TestCaseStats{} = stats}) do
    {
      :testsuite,
      [
        errors: stats.errors,
        failures: stats.failures,
        name: name,
        tests: stats.tests,
        time: stats.time |> format_time()
      ],
      for test <- stats.test_cases do
        generate_testcases(test)
      end
    }
  end

  defp us_to_ms(us), do: div(us, 10_000)

  defp format_ms(ms) do
    if ms < 10 do
      "0.0#{ms}"
    else
      ms = div(ms, 10)
      "#{div(ms, 10)}.#{rem(ms, 10)}"
    end
  end

  defp generate_testcases(test) do
    {
      :testcase,
      [
        classname: Atom.to_charlist(test.case),
        name: Atom.to_string(test.name),
        time: test.time |> us_to_ms |> format_ms
      ],
      generate_test_body(test)
    }
  end

  defp generate_test_body(%ExUnit.Test{state: nil}), do: []

  defp generate_test_body(%ExUnit.Test{state: {:skip, _}}) do
    [{:skipped, [], []}]
  end

  defp generate_test_body(%ExUnit.Test{state: {:failed, [{kind, reason, stacktrace} | _]}}) do
    generate_test_body(%ExUnit.Test{state: {:failed, {kind, reason, stacktrace}}})
  end

  defp generate_test_body(%ExUnit.Test{state: {:failed, {kind, reason, stacktrace}}} = test) do
    formatted_stack = Exception.format_stacktrace(stacktrace)

    message =
      case reason do
        %ExUnit.AssertionError{} ->
          ExUnit.Formatter.format_assertion_error(
            test,
            reason,
            stacktrace,
            :infinity,
            fn _, msg -> msg end,
            ""
          )

        other ->
          if Exception.exception?(other), do: Exception.message(other), else: inspect(other)
      end

    exception_kind =
      case kind do
        error when is_atom(error) -> Atom.to_string(error)
        other -> inspect(other)
      end

    [
      {:failure, [message: exception_kind <> ": " <> message],
       [
         String.to_charlist(formatted_stack)
       ]}
    ]
  end

  defp generate_test_body(%ExUnit.Test{state: {:invalid, module}}) do
    [{:error, [message: "Invalid module #{inspect(module)}"], []}]
  end
end
