defmodule FormatterTest do
  use ExUnit.Case, async: false

  import SweetXml

  defmacrop defsuite(do: block) do
    quote do
      {:module, name, _, _} =
        defmodule unquote(Module.concat(__MODULE__, :"Test#{System.unique_integer([:positive])}")) do
          use ExUnit.Case

          unquote(block)
        end

      name
    end
  end

  describe "properties" do
    test "contains seed" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output(seed: 0)

      assert '0' ==
               xpath(output, ~x{/testsuites/testsuite/properties/property[@name="seed"]/@value})
    end

    test "contains date" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output(seed: 0)

      assert_xpath(output, ~x{/testsuites/testsuite/properties/property[@name="date"]})
    end
  end

  describe "testsuites" do
    test "tag is present as a root" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output()

      assert_xpath(output, ~x{/testsuites})
    end
  end

  describe "testsuite" do
    test "direct descendant of testsuites" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output()

      assert_xpath(output, ~x{/testsuites/testsuite})
    end

    for attr <- ~w[tests errors failures] do
      test "has attribute #{attr}" do
        defsuite do
          test "it will fail", do: assert(false)
        end

        output = run_and_capture_output()

        assert output |> xpath(~x{//testsuite/@#{unquote(attr)}}) |> List.to_integer()
      end
    end

    test "suite name matches the module atom" do
      name =
        defsuite do
          test "it will fail", do: assert(false)
        end

      output = run_and_capture_output()

      assert Atom.to_charlist(name) == xpath(output, ~x{//testsuite/@name})
    end

    test "counts matches expected" do
      defsuite do
        test "pass", do: assert(true)

        test "fail", do: assert(false)
      end

      output = run_and_capture_output()

      # assert it contains correct suite
      assert %{errors: '0', failures: '1', tests: '2'} =
               xpath(output, ~x"//testsuite",
                 errors: ~x"./@errors",
                 failures: ~x"./@failures",
                 tests: ~x"./@tests"
               )
    end

    test "have time attribute" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output()

      assert output |> xpath(~x{//testsuite/@time}) |> List.to_float()
    end
  end

  describe "failure" do
    test "contains proper message" do
      defsuite do
        test "fails", do: assert(false)
      end

      output = run_and_capture_output()

      assert_xpath(
        output,
        ~x{//testcase[@name="test fails"]/failure[@message="Expected truthy, got false"]}
      )
    end

    test "it counts raises as failures" do
      defsuite do
        test "raise", do: raise(ArgumentError)
      end

      output = run_and_capture_output()

      assert %{failures: '1'} = xpath(output, ~x"//testsuite", failures: ~x"./@failures")

      assert_xpath(
        output,
        ~x{//testcase[@name="test raise"]/failure[@message="error: argument error"]}
      )
    end

    test "it can handle empty reason" do
      defmodule RaiseWithNoReason do
        use ExUnit.Case

        test "throw", do: throw(nil)
      end

      output = run_and_capture_output()

      assert_xpath(
        output,
        ~x{//testcase[@name="test throw"]/failure[@message="throw: nil"]}
      )
    end

    @tag :capture_log
    test "it can handle crashed process" do
      defsuite do
        test "linked process raise" do
          spawn_link(fn -> raise ArgumentError end)

          assert_receive :ok
        end
      end

      output = run_and_capture_output()

      assert_xpath(output, ~x{//testcase[@name="test linked process raise"]/failure})
    end

    test "it can handle empty message" do
      defmodule NilMessageError do
        defexception message: nil, customMessage: "A custom error occured !"
      end

      defsuite do
        test "raises without message", do: raise(NilMessageError)
      end

      output = run_and_capture_output()

      assert_xpath(output, ~x{//testcase[@name="test raises without message"]/failure})
    end
  end

  describe "skipped" do
    test "have skipped child" do
      defsuite do
        @tag :foo
        test "skip", do: assert(true)

        test "don't skip", do: assert(true)
      end

      output = run_and_capture_output(exclude: [:foo])

      assert_xpath(output, ~x{//testcase[@name="test skip"]/skipped})
      refute xpath(output, ~x{//testcase[@name="test don't skip"]/skipped})
    end
  end

  describe "error" do
    test "when `setup_all` fails" do
      defsuite do
        setup_all do: raise("Foo")

        test "errored", do: assert(true)
      end

      output = run_and_capture_output()

      assert_xpath(output, ~x{//testcase[@name="test errored"]/error})
    end
  end

  describe "testcase" do
    setup do
      on_exit(fn -> reset_config() end)
      :ok
    end

    if System.otp_release() >= "20" do
      test "it can include unicode in test names" do
        defsuite do
          test "make sure 3 ≤ 4" do
            flunk("This error contains unicodes in failure message -> öäü ≤")
          end
        end

        output = run_and_capture_output()

        assert_xpath(output, ~x{//testcase[@name="test make sure 3 ≤ 4"]})

        %{message: chars} =
          xpath(output, ~x{//testcase[@name="test make sure 3 ≤ 4"]/failure},
            message: ~x"./@message"
          )

        assert "This error contains unicodes in failure message -> öäü ≤" =
                 String.Chars.to_string(chars)
      end

      test "has file attribute when configured to" do
        defsuite do
          test "it will fail", do: assert(false)
        end

        put_config(:include_filename?, true)
        output = run_and_capture_output()

        assert xpath(output, ~x{//testsuite/testcase/@file}s) == "test/formatter_test.exs"
      end

      test "has file attribute with line when configured to" do
        defsuite do
          test "it will fail", do: assert(false)
        end

        put_config(:include_filename?, true)
        put_config(:include_file_line?, true)
        output = run_and_capture_output()

        assert xpath(output, ~x{//testsuite/testcase/@file}s) == "test/formatter_test.exs:261"
      end

      test "does not have file attribute when not configured to" do
        defsuite do
          test "it will fail", do: assert(false)
        end

        put_config(:include_filename?, false)
        output = run_and_capture_output()

        assert xpath(output, ~x{//testsuite/testcase/@file}s) == ""
      end

      test "makes path relative to project_dir if set" do
        defsuite do
          test "it will fail", do: assert(false)
        end

        parent_dir = Path.expand("../..", __DIR__)
        repo_dir_name = Path.expand("..", __DIR__) |> Path.basename()

        put_config(:include_filename?, true)
        put_config(:project_dir, parent_dir)
        output = run_and_capture_output()

        assert xpath(output, ~x{//testsuite/testcase/@file}s) ==
                 "#{repo_dir_name}/test/formatter_test.exs"
      end
    end
  end

  describe "format_time/1" do
    test "it can format time" do
      assert JUnitFormatter.format_time(1_000_000) == "1.0000"
      assert JUnitFormatter.format_time(10_000) == "0.0100"
      assert JUnitFormatter.format_time(20_000) == "0.0200"
      assert JUnitFormatter.format_time(110_000) == "0.1100"
      assert JUnitFormatter.format_time(1_100_000) == "1.1000"
    end
  end

  describe "configuration" do
    setup do
      on_exit(&reset_config/0)
      :ok
    end

    test "it can retrieve report file path" do
      assert JUnitFormatter.get_report_file_path() ==
               "#{Mix.Project.app_path()}/report_file_test.xml"

      put_config(:report_file, "abc.xml")
      assert JUnitFormatter.get_report_file_path() == "#{Mix.Project.app_path()}/abc.xml"

      put_config(:report_dir, "/tmp")
      assert JUnitFormatter.get_report_file_path() == "/tmp/abc.xml"
    end

    test "it can prepend the project name to the report file" do
      put_config(:prepend_project_name?, true)

      assert get_config(:report_file) == "report_file_test.xml"

      assert JUnitFormatter.get_report_file_path() ==
               "#{Mix.Project.app_path()}/junit_formatter-report_file_test.xml"
    end

    test "it can put the report file in a project sub-directory" do
      put_config(:use_project_subdirectory?, true)

      assert get_config(:report_file) == "report_file_test.xml"

      assert JUnitFormatter.get_report_file_path() ==
               "#{Mix.Project.app_path()}/junit_formatter/report_file_test.xml"
    end

    test "create directory at init" do
      tmp_dir = Path.join([Mix.Project.app_path(), System.tmp_dir!()])

      put_config(:automatic_create_dir?, true)
      put_config(:report_dir, tmp_dir)

      {:ok, _} = JUnitFormatter.init(seed: 1)

      assert File.exists?(tmp_dir)
      File.rmdir!(tmp_dir)
    end

    test "create sub-directory at init" do
      tmp_dir = Path.join([Mix.Project.app_path(), System.tmp_dir!()])

      put_config(:use_project_subdirectory?, true)
      put_config(:automatic_create_dir?, true)
      put_config(:report_dir, tmp_dir)

      {:ok, _} = JUnitFormatter.init(seed: 1)

      assert File.exists?(Path.join(tmp_dir, "junit_formatter"))
      File.rm_rf!(tmp_dir)
    end

    test "always create sub-directory at init even without automatic_create_dir?" do
      tmp_dir = Path.join([Mix.Project.app_path(), System.tmp_dir!()])

      put_config(:use_project_subdirectory?, true)
      put_config(:automatic_create_dir?, false)
      put_config(:report_dir, tmp_dir)

      {:ok, _} = JUnitFormatter.init(seed: 1)

      assert File.exists?(Path.join(tmp_dir, "junit_formatter"))
      File.rm_rf!(tmp_dir)
    end

    test "create exist directory at init" do
      tmp_dir = Path.join([Mix.Project.app_path(), System.tmp_dir!()])

      put_config(:automatic_create_dir?, true)
      put_config(:report_dir, tmp_dir)

      File.mkdir!(tmp_dir)

      {:ok, _} = JUnitFormatter.init(seed: 1)

      assert File.exists?(tmp_dir)
      File.rmdir!(tmp_dir)
    end
  end

  # Utilities --------------------
  defp reset_config do
    put_config(:report_file, "report_file_test.xml")
    put_config(:report_dir, Mix.Project.app_path())
    put_config(:prepend_project_name?, false)
    put_config(:include_file_line?, false)
    put_config(:automatic_create_dir?, false)
    put_config(:use_project_subdirectory?, false)
    put_config(:project_dir, nil)
  end

  defp get_config(name), do: Application.get_env(:junit_formatter, name)
  defp put_config(name, value), do: Application.put_env(:junit_formatter, name, value)

  defp run_and_capture_output(opts \\ []) do
    ExUnit.configure(Keyword.merge(opts, formatters: [JUnitFormatter]))

    funs = ExUnit.Server.__info__(:functions)

    if Keyword.has_key?(funs, :modules_loaded) do
      apply(ExUnit.Server, :modules_loaded, [])
    else
      apply(ExUnit.Server, :cases_loaded, [])
    end

    ExUnit.run()
    File.read!(JUnitFormatter.get_report_file_path()) <> "\n"
  end

  defp assert_xpath(xml, xpath) do
    assert xpath(xml, xpath), "Path #{inspect(xpath.path)} do not match #{inspect(xml)}"
  end
end
