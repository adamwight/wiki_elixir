# Wiki Elixir

This project provides Elixir client modules work with Wikipedia (and other
MediaWiki) APIs and data sources.  It currently supports the [Action API](https://www.mediawiki.org/wiki/Special:MyLanguage/API:Main_page),
query continuation, [EventStreams](https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams) relaying, and some of the
[RESTBase API](https://www.mediawiki.org/wiki/REST_API).

Everything you'll find here is beta-quality, please suggest improvements!

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

See the `examples/` directory for scripts demonstrating each module.

## Development

The project's homepage is currently [on GitLab](https://gitlab.com/adamwight/wiki_elixir).
To contribute, please submit an issue or a pull request.
