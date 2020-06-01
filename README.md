# Wiki Elixir

Unofficial Elixir client modules for Wikipedia and other MediaWiki sites.

About the current version: [Documentation and examples](https://hexdocs.pm/wiki_elixir/api-reference.html)

Overview:
* `Wiki.Action` connects to the [Action API](https://www.mediawiki.org/wiki/Special:MyLanguage/API:Main_page),
a rich set of commands to query or edit almost anything on a wiki.
* `Wiki.EventStreams` to access [EventStreams](https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams),
a real-time feed of events.
* `Wiki.Ores` to access the [ORES](https://www.mediawiki.org/wiki/ORES) service [API](https://ores.wikimedia.org/v3/),
machine-learning models for estimating revision and edit quality.

This library is beta-quality, and written by an beginner Elixir probrammer so
please suggest improvements.  The public interface will evolve, and the
[0.x](https://semver.org/) releases in particular are likely to include breaking changes
between versions.  These will be documented in the [change log](CHANGELOG.md).

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
|> Wiki.Action.get(
  action: :query,
  meta: :siteinfo,
  siprop: :statistics
)
|> (&(&1.result)).()
|> IO.inspect()
```

See the module documentation for detailed usage and more examples.

### Error handling

Methods are all assertive, and will throw a `RuntimeError` whenever a network
or API error is detected.

### Defaults

Some parameters are set by default, but can be overridden by including in the query.

* The `:format` parameter defaults to `:json`.
* `:formatversion` defaults to `2`.

A few configuration variables are available under the `:wiki_elixir` application,
but aren't necessary for normal use.  Example overrides can be seen in
[config/test.exs](config/test.exs), in this case to mock network access.

* `:eventsource_adapter` - Defaults to `HTTPoison`, this will be used for the
EventStreams HTTP client.
* `:eventstream_endpoint` - API endpoint for `Wiki.EventStreams`, might be
overridden to target a staging server for example.
* `:ores_endpoint` - API endpoint for `Wiki.Ores`.
* `:tesla_adapter` - This will fall back to `Tesla.Adapter.Hackney`, as a stable
client which performs certificate validation.
* `:user_agent` - Sent in request headers, defaults to `wiki_elixir/<version>`...

## Development

The [project's homepage](https://gitlab.com/adamwight/wiki_elixir) is currently on GitLab.
To contribute, please submit an issue or a merge request.

Several linters are configured, the easiest way to use them is to install the
pre-push git hook using,

```shell script
mix git_hooks.install
```
