defmodule Mix.Tasks.Credence do
  @shortdoc "Runs the credence semantic linter on the given files"
  @moduledoc """
  Runs the credence semantic linter/fixer on the given Elixir source files.

  Accepts explicit file paths, directories, and glob patterns. Directories
  are recursively searched for `.ex` and `.exs` files. Glob patterns are
  expanded by the task itself, so quoted patterns work correctly across all
  shells.

  ## Usage

      mix credence ./lib
      mix credence file1.ex file2.ex lib/my_module.ex
      mix credence "lib/**/*.ex"
      mix credence "lib/**/*.ex" "test/**/*.exs"

  Each matched file is read, passed through `Credence.fix/2`, and written
  back with the fixed source. Any remaining issues that could not be
  auto-fixed are printed to stderr.

  ## Options

    * `--check` - Report issues without modifying files (exit 1 if issues found)
    * `-v` / `--verbose` - Show debug-level log output from the fix pipeline

  ## Examples

      mix credence lib/my_app/router.ex
      mix credence "lib/**/*.{ex,exs}"
      mix credence --check "lib/**/*.ex" "test/**/*.exs"

  """

  use Mix.Task

  require Logger

  @impl Mix.Task
  def run(args) do
    {opts, patterns} = parse_args(args)

    if patterns == [] do
      Mix.raise("Expected at least one file path or glob pattern. Usage: mix credence <file1|glob> ...")
    end

    unless opts[:verbose] do
      Logger.configure(level: :info)
    end

    files = expand_patterns(patterns)

    results = Enum.map(files, &process_file(&1, opts))

    total_issues = Enum.sum(Enum.map(results, fn r -> length(r.issues) end))
    total_applied = Enum.sum(Enum.map(results, fn r -> length(r.applied_rules) end))

    print_summary(length(files), total_applied, total_issues)

    if opts[:check] && total_issues > 0 do
      exit({:shutdown, 1})
    end
  end

  defp parse_args(args) do
    {opts, patterns, _} = OptionParser.parse(args, strict: [check: :boolean, verbose: :boolean], aliases: [v: :verbose])
    {opts, patterns}
  end

  @glob_chars ~r/[\*\?\{\}\[]/

  defp expand_patterns(patterns) do
    patterns
    |> Enum.flat_map(fn pattern ->
      cond do
        Regex.match?(@glob_chars, pattern) ->
          case Path.wildcard(pattern) do
            [] -> Mix.raise("No files matched pattern: #{pattern}")
            files -> files
          end

        File.dir?(pattern) ->
          pattern
          |> Path.join("**/*.{ex,exs}")
          |> Path.wildcard()

        true ->
          [pattern]
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp process_file(path, opts) do
    unless File.exists?(path) do
      Mix.raise("File not found: #{path}")
    end

    source = File.read!(path)
    result = Credence.fix(source)

    if result.applied_rules != [] do
      print_applied(path, result.applied_rules)

      unless opts[:check] do
        File.write!(path, result.code)
      end
    end

    if result.issues != [] do
      print_issues(path, result.issues)
    end

    result
  end

  defp print_applied(path, applied_rules) do
    rules_summary =
      applied_rules
      |> Enum.map(fn
        {mod, :reverted} -> "  #{inspect(mod)} (reverted)"
        {mod, count} -> "  #{inspect(mod)} (#{count})"
      end)
      |> Enum.join("\n")

    Mix.shell().info("#{path}: fixed\n#{rules_summary}")
  end

  defp print_issues(path, issues) do
    issues
    |> Enum.each(fn issue ->
      Mix.shell().error("#{path}: #{issue.message}")
    end)
  end

  defp print_summary(file_count, total_applied, total_issues) do
    Mix.shell().info("")

    cond do
      total_applied == 0 && total_issues == 0 ->
        Mix.shell().info("#{file_count} file(s) checked — all clean.")

      total_issues == 0 ->
        Mix.shell().info(
          "#{file_count} file(s) checked — #{total_applied} rule(s) applied, no remaining issues."
        )

      true ->
        Mix.shell().info(
          "#{file_count} file(s) checked — #{total_applied} rule(s) applied, #{total_issues} issue(s) remaining."
        )
    end
  end
end
