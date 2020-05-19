# mix run ./examples/echo_action.exs

Wiki.Action.new("https://de.wikipedia.org/w/api.php")
|> Wiki.Action.stream(%{
  action: :query,
  format: :json,
  list: :recentchanges,
  rclimit: 1
})
|> Stream.take(10)
|> Enum.flat_map(fn response -> response["query"]["recentchanges"] end)
|> Enum.map(fn rc -> rc["timestamp"] <> " " <> rc["title"] end)
|> IO.inspect
