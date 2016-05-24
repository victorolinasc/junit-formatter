defmodule FormatterTest do
  use ExUnit.Case

  test "that a valid test generates a proper report" do

    :timer.sleep 1223
    
    defmodule ValidTest do
      use ExUnit.Case

      test "the truth" do
        assert 1 + 1 == 2
      end
    end

    output = run_and_capture_output |> strip_time_and_line_number
    assert output =~ read_fixture("valid_test.xml")
  end

  test "that an invalid test generates a proper report" do

    defmodule FailureTest do
      use ExUnit.Case

      test "it will fail" do
        assert 1 + 1 == 3
      end
    end

    output = run_and_capture_output |> strip_time_and_line_number
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

    output = run_and_capture_output |> strip_time_and_line_number

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

    output = run_and_capture_output |> strip_time_and_line_number

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

    output = run_and_capture_output |> strip_time_and_line_number
    
    assert output =~ "<testcase classname=\"Elixir.FormatterTest.RaiseWithNoReason\" name=\"test it raises without reason\" ><failure message=\"throw: nil\">    test/formatter_test.exs FormatterTest.RaiseWithNoReason.\"test it raises without reason\"/1\n</failure></testcase>"
  end

  test "it can format time" do
    assert JUnitFormatter.format_time(1000000) == "1.0"
    assert JUnitFormatter.format_time(10000) == "0.01"
    assert JUnitFormatter.format_time(20000) == "0.02"
    assert JUnitFormatter.format_time(110000) == "0.1"
    assert JUnitFormatter.format_time(1100000) == "1.1"
  end
  
  # Utilities --------------------
  
  defp read_fixture(extra) do
    File.read! Path.join(Path.expand("fixtures", __DIR__), extra)
  end

  defp run_and_capture_output do
    ExUnit.configure formatters: [JUnitFormatter]
    ExUnit.run

    report = Application.get_env :junit_formatter, :report_file, "test-junit-report.xml"
    File.read!(Mix.Project.app_path <> "/" <> report) <> "\n"
  end

  defp strip_time_and_line_number(output) do
    output = String.replace output, ~r/time=\"[0-9]+\.[0-9]+\"/, ""
    file = List.last String.split __ENV__.file, ~r/\//
      String.replace output, ~r/#{file}:[0-9]+:/, file
  end
  
end
