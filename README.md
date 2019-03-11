# Wiki Elixir

This project provides Elixir connectors to work with Wikipedia (and other
MediaWiki) data sources.  It supports streaming recent changes processing and
(TODO) should be able to wrap API calls and continuations in the future.

## Installation

The package can be installed by adding `wiki_elixir` to your list of dependencies in
`mix.exs`,

```elixir
def deps do
  [
    {:wiki_elixir, "~> 0.1"}
  ]
end
```

Documentation can be generated with `mix docs`.

## Usage

See the `examples/` directory for projects demonstrating each module.

## Development

The project's homepage is currently [on GitHub](https://github.com/adamwight/wiki_elixir).
To contribute, please submit an issue or a pull request.

Potential future directions:
* Wrap the [MediaWiki action API](https://www.mediawiki.org/wiki/API:Main_page).
* Wrap the [REST API](https://www.mediawiki.org/wiki/REST_API).
