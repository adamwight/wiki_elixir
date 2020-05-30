import Config

config :wiki_elixir,
  tesla_adapter: Wiki.Tests.TeslaAdapterMock

config :wiki_elixir,
  eventsource_adapter: Wiki.Tests.HTTPoisonMock
