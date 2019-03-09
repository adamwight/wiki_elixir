# Wiki Elixir

This project provides Elixir connectors to work with Wikipedia (and other
MediaWiki) data sources.  It supports realtime feed processing and (TODO)
should be able to wrap API calls and continuations in the future.

The `examples` directory shows how to use this library.

## Installation

The package can be installed by adding `wiki_elixir` to your list of dependencies in
`mix.exs`, currently only available from GitHub:

```elixir
def deps do
  [
    {:wiki_elixir, github: "adamwight/wiki_elixir"}
  ]
end
```

Documentation can be generated with `mix docs`.
