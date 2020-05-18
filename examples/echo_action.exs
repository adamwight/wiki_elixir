Wiki.Action.new(
  Application.get_env(:wiki_elixir, :default_site_api)
)
|> Wiki.Action.authenticate(
  Application.get_env(:wiki_elixir, :username),
  Application.get_env(:wiki_elixir, :password)
)
|> Wiki.Action.get(%{
  action: :query,
  meta: :tokens,
  type: :csrf
})
|> (&Wiki.Action.post(&1, %{
  action: :edit,
  title: "Sandbox",
  assert: :user,
  token: &1.result["query"]["tokens"]["csrftoken"],
  appendtext: "~~~~ was here."
})).()
|> (&(&1.result)).()
|> Jason.encode!(pretty: true)
|> IO.puts

#WikiAction.get(%{
#  action: :query,
#  format: :json,
#  meta: :siteinfo,
#  siprop: :statistics
#})
#|> IO.inspect()

#WikiAction.stream(%{
#  action: :query,
#  format: :json,
#  list: :recentchanges,
#  rclimit: 1
#})
#|> Stream.take(10)
#|> Enum.flat_map(fn response -> response["query"]["recentchanges"] end)
#|> Enum.map(fn rc -> rc["timestamp"] <> " " <> rc["title"] end)
#|> IO.inspect
