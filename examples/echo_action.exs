WikiAction.stream(%{
  action: :query,
  format: :json,
  list: :recentchanges,
  rclimit: 2,
})
|> Stream.take(5)
|> Enum.flat_map(fn response -> response["query"]["recentchanges"] end)
|> Enum.map(fn rc -> rc["timestamp"] <> " " <> rc["title"] end)
|> IO.inspect