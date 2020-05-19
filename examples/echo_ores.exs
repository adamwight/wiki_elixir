# mix run examples/echo_ores.exs

Wiki.Ores.new("enwiki")
|> Wiki.Ores.request(%{
  models: ["damaging", "wp10"],
  revids: 456789
})
|> Jason.encode!(pretty: true)
|> IO.puts()