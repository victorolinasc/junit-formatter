defmodule FormatterTest do
  use ExUnit.Case, async: false

  test "that a valid test generates a proper report" do

    defmodule ValidTest do
      use ExUnit.Case

      test "the truth" do
        assert 1 + 1 == 2
      end
    end

    output = run_and_capture_output() |> strip_time_and_line_number
    assert output =~ read_fixture("valid_test.xml")
  end

  test "that an invalid test generates a proper report" do

    defmodule FailureTest do
      use ExUnit.Case

      test "it will fail" do
        assert 1 + 1 == 3
      end
    end

    output = run_and_capture_output() |> strip_time_and_line_number
    assert output =~ read_fixture("invalid_test.xml")
  end

  test "valid and invalid tests generates a proper report" do

    defmodule ValidAndInvalidTest do
      use ExUnit.Case

      test "the truth" do
        assert 1 + 1 == 2
      end

      test "it will fail" do
        assert 1 + 1 == 3
      end
    end

    output = run_and_capture_output() |> strip_time_and_line_number

    # can't ensure order. Assert it contains both cases
    assert output =~ "<testcase classname=\"Elixir.FormatterTest.ValidAndInvalidTest\" name=\"test the truth\" />"
    assert output =~ "<testcase classname=\"Elixir.FormatterTest.ValidAndInvalidTest\" name=\"test it will fail\" ><failure message=\"error: Assertion with == failed\">    test/formatter_test.exs FormatterTest.ValidAndInvalidTest.\"test it will fail\"/1\n</failure></testcase>"

    # assert it contains correct suite
    assert output =~ "<testsuite errors=\"0\" failures=\"1\" name=\"Elixir.FormatterTest.ValidAndInvalidTest\" tests=\"2\" >"
  end

  test "it counts raises as failures" do
    defmodule RaiseAsFailureTest do
      use ExUnit.Case

      test "it counts raises" do
        raise ArgumentError
      end
    end

    output = run_and_capture_output() |> strip_time_and_line_number

    assert output =~ "<testsuite errors=\"0\" failures=\"1\" name=\"Elixir.FormatterTest.RaiseAsFailureTest\" tests=\"1\""
    assert output =~ "<testcase classname=\"Elixir.FormatterTest.RaiseAsFailureTest\" name=\"test it counts raises\" ><failure message=\"error: argument error\">    test/formatter_test.exs FormatterTest.RaiseAsFailureTest.\"test it counts raises\"/1"
  end

  test "it can handle empty reason" do
    defmodule RaiseWithNoReason do
      use ExUnit.Case

      test "it raises without reason" do
        throw nil
      end
    end

    output = run_and_capture_output() |> strip_time_and_line_number

    assert output =~ "<testcase classname=\"Elixir.FormatterTest.RaiseWithNoReason\" name=\"test it raises without reason\" ><failure message=\"throw: nil\">    test/formatter_test.exs FormatterTest.RaiseWithNoReason.\"test it raises without reason\"/1\n</failure></testcase>"
  end

  test "it can handle empty message" do
    defmodule NilMessageError do
      defexception [message: nil, customMessage: "A custom error occured !"]
    end

    defmodule RaiseWithNoMessage do
      use ExUnit.Case

      test "it raises without message" do
        raise NilMessageError
      end
    end

    output = run_and_capture_output() |> strip_time_and_line_number()

    assert output =~ "<testcase classname=\"Elixir.FormatterTest.RaiseWithNoMessage\" name=\"test it raises without message\" ><failure message=\"error: %FormatterTest.NilMessageError{customMessage: &quot;A custom error occured !&quot;, message: nil}\">    test/formatter_test.exs FormatterTest.RaiseWithNoMessage.\"test it raises without message\"/1\n</failure></testcase>"
  end

  test "it can count skipped tests" do
    defmodule SkipTest do
      use ExUnit.Case

      @tag :skip
      test "it just skips" do
        :ok
      end
    end

    output = run_and_capture_output() |> strip_time_and_line_number()

    assert output =~ "<testcase classname=\"Elixir.FormatterTest.SkipTest\" name=\"test it just skips\" ><skipped/></testcase>"
  end

  test "it can format time" do
    assert JUnitFormatter.format_time(1000000) == "1.0"
    assert JUnitFormatter.format_time(10000) == "0.01"
    assert JUnitFormatter.format_time(20000) == "0.02"
    assert JUnitFormatter.format_time(110000) == "0.1"
    assert JUnitFormatter.format_time(1100000) == "1.1"
  end

  test "it can retrieve report file path" do

    # default
    assert get_config(:report_file) == "report_file_test.xml"

    assert JUnitFormatter.get_report_file_path == "#{Mix.Project.app_path}/report_file_test.xml"

    put_config(:report_file, "abc.xml")
    assert JUnitFormatter.get_report_file_path == "#{Mix.Project.app_path}/abc.xml"

    put_config(:report_dir, "/tmp")
    assert JUnitFormatter.get_report_file_path == "/tmp/abc.xml"
  end

  # Utilities --------------------
  defp get_config(name), do: Application.get_env(:junit_formatter, name)
  defp put_config(name, value), do: Application.put_env(:junit_formatter, name, value)

  defp read_fixture(extra) do
    Path.expand("fixtures", __DIR__) |> Path.join(extra) |> File.read!
  end

  defp run_and_capture_output do
    ExUnit.configure(formatters: [JUnitFormatter], exclude: :skip)

    # Elixir 1.3 introduced this function changing the behaviour of custom calls
    # to ExUnit.run. We need to call this function if available.
    if Keyword.has_key?(ExUnit.Server.__info__(:functions), :cases_loaded) do
      ExUnit.Server.cases_loaded()
    end

    ExUnit.run
    File.read!(JUnitFormatter.get_report_file_path) <> "\n"
  end

  defp strip_time_and_line_number(output) do
    output = String.replace output, ~r/time=\"[0-9]+\.[0-9]+\"/, ""
    file = List.last String.split __ENV__.file, ~r/\//
      String.replace output, ~r/#{file}:[0-9]+:/, file
  end

end
