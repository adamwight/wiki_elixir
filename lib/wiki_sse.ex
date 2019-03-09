defmodule WikiSSE do
  @moduledoc """
  Wikipedia's built-in Recent Changes feed allows us to poll up to 50 recent
  edits at a time.  This module applies a callback to each edit.  The default
  callback is for demonstration, and will print a summary of each edit, one per
  line.
  """

  @sse_feed "https://stream.wikimedia.org/v2/stream/recentchange"

  @doc """
  """
  def start(:normal, []) do
    start(:normal, [@sse_feed, &WikiSSE.demo_event_callback/1])
  end

  def start(:normal, [endpoint, event_callback]) do
    # TODO: needs a supervisor
    watcher = Task.start_link(fn ->
      watch_feed(event_callback)
    end)
    read_feed(endpoint, elem(watcher, 1))
  end

  defp read_feed(endpoint, watcher) do
    EventsourceEx.new(endpoint, stream_to: watcher)
  end

  defp watch_feed(event_callback) do
    receive do
      message ->
        event_callback.(message)
    end
    watch_feed(event_callback)
  end

  def demo_event_callback(message) do
    data = Poison.decode!(message.data)
    {dt, wiki, title, user} = {data["meta"]["dt"], data["wiki"], data["title"], data["user"]}
    IO.puts "#{dt}: #{wiki} #{title} edited by #{user}"
  end
end
