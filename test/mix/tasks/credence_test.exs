defmodule Mix.Tasks.CredenceTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @tmp_dir "test/tmp"

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
  end

  test "raises when no files are given" do
    assert_raise Mix.Error, ~r/Expected at least one file path or glob pattern/, fn ->
      Mix.Tasks.Credence.run([])
    end
  end

  test "raises when file does not exist" do
    assert_raise Mix.Error, ~r/File not found/, fn ->
      Mix.Tasks.Credence.run(["nonexistent.ex"])
    end
  end

  test "raises when a glob pattern matches no files" do
    assert_raise Mix.Error, ~r/No files matched pattern/, fn ->
      Mix.Tasks.Credence.run(["#{@tmp_dir}/**/*.ex"])
    end
  end

  test "expands a glob pattern and processes matched files" do
    path1 = Path.join(@tmp_dir, "a.ex")
    path2 = Path.join(@tmp_dir, "b.ex")

    code = """
    defmodule Hello do
      def hello, do: :world
    end
    """

    File.write!(path1, code)
    File.write!(path2, code)

    capture_io(fn ->
      Mix.Tasks.Credence.run(["#{@tmp_dir}/*.ex"])
    end)

    assert File.read!(path1) == code
    assert File.read!(path2) == code
  end

  test "deduplicates files when a path matches multiple patterns" do
    path = Path.join(@tmp_dir, "dup.ex")
    File.write!(path, "defmodule Dup do\n  def hello, do: :world\nend\n")

    results =
      capture_io(fn ->
        Mix.Tasks.Credence.run([path, path])
      end)

    assert results =~ "1 file(s) checked"
  end

  test "processes a clean file without modification" do
    path = Path.join(@tmp_dir, "clean.ex")

    code = """
    defmodule Clean do
      def hello, do: :world
    end
    """

    File.write!(path, code)

    capture_io(fn ->
      Mix.Tasks.Credence.run([path])
    end)

    assert File.read!(path) == code
  end

  test "--check flag does not modify files" do
    path = Path.join(@tmp_dir, "check_only.ex")

    code = """
    defmodule CheckOnly do
      def sum(list) do
        Enum.reduce(list, 0, fn x, acc -> acc + x end)
      end
    end
    """

    File.write!(path, code)

    capture_io(fn ->
      Mix.Tasks.Credence.run(["--check", path])
    end)

    assert File.read!(path) == code
  end
end
