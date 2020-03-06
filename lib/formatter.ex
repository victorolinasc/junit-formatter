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

  defmodule Stats do
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

  defstruct cases: %{}, properties: %{}

  @impl true
  def init(opts) do
    {:ok,
     %__MODULE__{
       properties: %{
         seed: opts[:seed],
         date: DateTime.to_iso8601(DateTime.utc_now())
       }
     }}
  end

  @impl true
  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    # do the real magic
    suites = Enum.map(config.cases, &generate_testsuite_xml(&1, config.properties))
    # wrap result in a root node (not adding any attribute to root)
    result = :xmerl.export_simple([{:testsuites, [], suites}], :xmerl_xml)

    # save the report in an xml file
    file_name = get_report_file_path()

    :ok = File.write!(file_name, result, [:write])

    if Application.get_env(:junit_formatter, :print_report_file, false) do
      IO.puts(:stderr, "Wrote JUnit report to: #{file_name}")
    end

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, config) do
    config = adjust_case_stats(test, nil, config)

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skip, _}} = test}, config) do
    config = adjust_case_stats(test, :skipped, config)

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _}} = test}, config) do
    config = adjust_case_stats(test, :skipped, config)

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, _failed}} = test}, config) do
    config = adjust_case_stats(test, :failures, config)

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _module}} = test}, config) do
    config = adjust_case_stats(test, :errors, config)

    {:noreply, config}
  end

  def handle_cast(_event, config), do: {:noreply, config}

  @doc "Formats time from nanos to seconds"
  @spec format_time(integer) :: binary
  def format_time(time), do: '~.4f' |> :io_lib.format([time / 1_000_000]) |> List.to_string()

  @doc """
  Helper function to get the full path of the generated report file.
  It can be passed 2 configurations
  - report_dir: full path of a directory (defaults to `Mix.Project.app_path()`)
  - report_file: name of the generated file (defaults to "test-junit-report.xml")
  """
  @spec get_report_file_path() :: String.t()
  def get_report_file_path do
    prepend = Application.get_env(:junit_formatter, :prepend_project_name?, false)

    report_file = Application.get_env(:junit_formatter, :report_file, "test-junit-report.xml")
    report_dir = Application.get_env(:junit_formatter, :report_dir, Mix.Project.app_path())
    prefix = if prepend, do: "#{Mix.Project.config()[:app]}-", else: ""

    Path.join(report_dir, prefix <> report_file)
  end

  # PRIVATE ------------

  defp adjust_case_stats(%ExUnit.Test{case: name, time: time} = test, type, state) do
    cases =
      Map.update(
        state.cases,
        name,
        struct(Stats, [{type, 1}, test_cases: [test], time: time, tests: 1]),
        fn stats ->
          stats =
            struct(
              stats,
              test_cases: [test | stats.test_cases],
              time: stats.time + time,
              tests: stats.tests + 1
            )

          if type, do: Map.update!(stats, type, &(&1 + 1)), else: stats
        end
      )

    %{state | cases: cases}
  end

  defp generate_testsuite_xml({name, %Stats{} = stats}, properties) do
    properties =
      for {name, value} <- properties do
        {:property, [name: name, value: value], []}
      end

    cases =
      for {test, idx} <- Enum.with_index(stats.test_cases, 1) do
        generate_testcases(test, idx)
      end

    {
      :testsuite,
      [
        errors: stats.errors,
        failures: stats.failures,
        name: name,
        tests: stats.tests,
        time: format_time(stats.time)
      ],
      [{:properties, [], properties} | cases]
    }
  end

  defp generate_testcases(test, idx) do
    attrs = [
      classname: Atom.to_string(test.case),
      name: Atom.to_string(test.name),
      time: format_time(test.time)
    ]

    attrs = maybe_add_filename(attrs, test.tags.file)

    {
      :testcase,
      attrs,
      generate_test_body(test, idx)
    }
  end

  defp generate_test_body(%ExUnit.Test{state: nil}, _idx), do: []

  defp generate_test_body(%ExUnit.Test{state: {atom, message}}, _idx)
       when atom in ~w[skip excluded]a do
    [{:skipped, [message: message], []}]
  end

  defp generate_test_body(%ExUnit.Test{state: {:failed, failures}} = test, idx) do
    body =
      test
      |> ExUnit.Formatter.format_test_failure(failures, idx, :infinity, fn _, msg -> msg end)
      |> :erlang.binary_to_list()

    [{:failure, [message: message(failures)], [body]}]
  end

  defp generate_test_body(%ExUnit.Test{state: {:invalid, %name{} = module}}, _idx),
    do: [{:error, [message: "Invalid module #{name}"], ['#{inspect(module)}']}]

  defp message([msg | _]), do: message(msg)
  defp message({_, %ExUnit.AssertionError{message: reason}, _}), do: reason
  defp message({:error, reason, _}), do: "error: #{Exception.message(reason)}"
  defp message({type, reason, _}) when is_atom(type), do: "#{type}: #{inspect(reason)}"
  defp message({type, reason, _}), do: "#{inspect(type)}: #{inspect(reason)}"

  defp maybe_add_filename(attrs, path) do
    if Application.get_env(:junit_formatter, :include_filename?) do
      Keyword.put(attrs, :file, Path.relative_to_cwd(path))
    else
      attrs
    end
  end
end
