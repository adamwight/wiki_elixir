client = WikiAction.authenticated_client(
  Application.get_env(:wiki_elixir, :username),
  Application.get_env(:wiki_elixir, :password)
)
response = WikiAction.get(client, %{
  action: :query,
  meta: :tokens,
  type: :csrf
})
WikiAction.post(client, %{
  action: :edit,
  title: "Sandbox",
  assert: :user,
  token: response["query"]["tokens"]["csrftoken"],
  appendtext: "~~~~ was here."
})
|> IO.inspect

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
