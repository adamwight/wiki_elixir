# Wiki Elixir

Unofficial Elixir client modules for Wikipedia and other MediaWiki sites.

Currently supported,
* `Wiki.Action` to access the [Action API](https://www.mediawiki.org/wiki/Special:MyLanguage/API:Main_page).
This is a rich set of commands to query or edit almost anything on a wiki.
* `Wiki.EventStreams` to access [EventStreams](https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams),
a real-time feed of events.
* `Wiki.Ores` to access the [ORES](https://www.mediawiki.org/wiki/ORES) service [API](https://ores.wikimedia.org/v3/),
machine-learning models for estimating revision and edit quality.

Considered for a future version,
* Client for the many Wikimedia [REST API](https://www.mediawiki.org/wiki/REST_API )s served through RESTBase.
See [issue #2](https://gitlab.com/adamwight/wiki_elixir/-/issues/2)
* Built-in [REST API](https://www.mediawiki.org/wiki/API:REST_API).

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

A simple call to the action API,

```elixir
Wiki.Action.new("https://de.wikipedia.org/w/api.php")
|> Wiki.Action.get(%{
  action: :query,
  meta: :siteinfo,
  siprop: :statistics
})
|> (&(&1.result)).()
|> IO.inspect()
```

See the module documentation for detailed usage and more examples.

The `:format` parameter defaults to `:json` and can be omitted unless you mean to
override the returned format.

## Development

The [project's homepage](https://gitlab.com/adamwight/wiki_elixir) is currently on GitLab.
To contribute, please submit an issue or a merge request.

Several linters are configured, the easiest way to use them is to install the
pre-push git hook using,

```shell script
mix git_hooks.install
```
