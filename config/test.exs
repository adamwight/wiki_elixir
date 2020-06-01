import Config

config :wiki_elixir,
  eventsource_adapter: Wiki.Tests.HTTPoisonMock,
  tesla_adapter: Wiki.Tests.TeslaAdapterMock,
  ores_endpoint: "https://ores.test/v3/scores/",
  eventstream_endpoint: "https://stream.test/v2/stream/"
