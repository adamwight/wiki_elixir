# mix run ./examples/echo_rest.exs

Wiki.Rest.Pageviews.pageviews_per_article("en.wikipedia.org", "Quarantine")
|> Jason.encode!(pretty: true)
|> IO.puts()