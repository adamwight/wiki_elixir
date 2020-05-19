# Wiki Elixir

This project provides Elixir client modules to work with Wikipedia and other
MediaWiki APIs.  It currently supports,
* `Wiki.Action` to access the [Action API](https://www.mediawiki.org/wiki/Special:MyLanguage/API:Main_page).
This is a rich set of commands to query or edit almost anything on a wiki.
* `Wiki.EventStreams` to access [EventStreams](https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams),
a real-time feed of events.
* `Wiki.Ores` to access the [ORES](https://www.mediawiki.org/wiki/ORES) [API](https://ores.wikimedia.org/v3/),
a machine-learning service for estimating revision and edit quality.
* `Wiki.Rest` to access [RESTBase](https://www.mediawiki.org/wiki/REST_API).

Everything you'll find here is beta-quality, please suggest improvements.  Expect the
public interface to change.

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
