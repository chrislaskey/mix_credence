# mix_credence

A `mix credence` command-line wrapper for the [credence](https://hex.pm/packages/credence) semantic linter.

Credence detects performance issues and non-idiomatic Elixir via AST analysis and automatically rewrites them — think `mix format` but for idioms. `mix_credence` lets you run it directly from the command line on specific files or glob patterns.

## Installation

Add `mix_credence` to your dependencies in `mix.exs`. Because it's a dev/test tool, mark it `runtime: false`.

To pin a specific release tag:

```elixir
def deps do
  [
    {:mix_credence, git: "https://github.com/chrislaskey/mix_credence", tag: "v0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

Or to always pull the latest from the main branch:

```elixir
def deps do
  [
    {:mix_credence, git: "https://github.com/chrislaskey/mix_credence", branch: "main", only: [:dev, :test], runtime: false}
  ]
end
```

Then fetch:

```bash
mix deps.get
```

## Usage

Pass one or more file paths or glob patterns:

```bash
# Single file
mix credence lib/my_app/router.ex

# Multiple explicit files
mix credence lib/my_app/router.ex lib/my_app/user.ex

# Glob pattern (quoted so the task expands it, works in all shells)
mix credence "lib/**/*.ex"

# Multiple glob patterns
mix credence "lib/**/*.ex" "test/**/*.exs"
```

Each matched file is read, passed through `Credence.fix/2`, and written back in place with the fixed source. Rules applied and any remaining issues are printed to the terminal.

### Check mode (no writes)

Use `--check` to report issues without modifying files. Exits with code `1` if any unfixable issues are found — useful for CI:

```bash
mix credence --check "lib/**/*.ex"
```

### Example output

```
lib/my_app/scores.ex: fixed
  Credence.Pattern.NoExplicitSumReduce (1)
  Credence.Pattern.NoSortThenReverse (1)

3 file(s) checked — 2 rule(s) applied, no remaining issues.
```

## How it works

`mix credence` delegates entirely to the `credence` library. Each file is passed as a string to `Credence.fix/2`, which runs the code through three phases:

1. **Syntax** — fixes code that won't parse
2. **Semantic** — fixes compiler warnings (unused variables, undefined functions)
3. **Pattern** — rewrites ~117 AST-level anti-patterns to idiomatic Elixir

See the [credence documentation](https://hexdocs.pm/credence) for the full list of rules.

## License

MIT
