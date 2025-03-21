# mix phx.new.yosu

A wrapper for mix phx.new with better defaults.

- Use short UUIDs with custom schema module
- Use utc_datetime_usec for timestamps
- Use credo for static analysis and formatter
- Add `mix check` alias to check compile, format, unlocked dependencies and credo

## Installation

`mix phx.new.yosu` generator can be installed by the command below:

```
$ mix archive.install hex phx_new_yosu
```


The package can be installed
by adding `phx_new_yosu` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phx_new_yosu, "~> 0.2.0"}
  ]
end
```
