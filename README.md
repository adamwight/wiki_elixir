# Wiki Elixir

This project provides unofficial Elixir client modules for Wikipedia and other
MediaWiki sites.  It currently supports,
* `Wiki.Action` to access the [Action API](https://www.mediawiki.org/wiki/Special:MyLanguage/API:Main_page).
This is a rich set of commands to query or edit almost anything on a wiki.
* `Wiki.EventStreams` to access [EventStreams](https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams),
a real-time feed of events.
* `Wiki.Ores` to access the [ORES](https://www.mediawiki.org/wiki/ORES) service [API](https://ores.wikimedia.org/v3/),
machine-learning models for estimating revision and edit quality.
* `Wiki.Rest` to access the Wikimedia [REST API](https://www.mediawiki.org/wiki/REST_API).

Everything you'll find here is beta-quality, please suggest improvements.  Expect the
public interface to change, this project uses [semantic versioning](https://semver.org/) and
the "0.x" releases should be taken literally.

## Installation

Install this package by adding `wiki_elixir` to your dependencies in `mix.exs`,

```elixir
def deps do
  [
    {:wiki_elixir, "~> 0.1"}
  ]
end
```

Documentation is generated with `mix docs`.

## Usage

Calling the action API,

```elixir
Wiki.Action.new("https://de.wikipedia.org/w/api.php")
|> Wiki.Action.get(%{
  action: :query,
  format: :json,
  meta: :siteinfo,
  siprop: :statistics
})
|> IO.inspect()
```

See each module for more detailed examples.

## Development

The project's homepage is currently [on GitLab](https://gitlab.com/adamwight/wiki_elixir).
To contribute, please submit an issue or a pull request.

Install the pre-push git hook using,

```shell script
mix git_hooks.install
```
