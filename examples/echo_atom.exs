WikiRecentChangesFeed.start_link(
  fn {_, author, _, _, _, diff_url, _, _, _, _html, title, timestamp} ->
    IO.puts "#{timestamp}: #{author} edited #{title}: #{diff_url}"
  end
)

Process.sleep(10_000)
