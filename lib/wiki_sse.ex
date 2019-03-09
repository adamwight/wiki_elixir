defmodule WikiSSE do
  @moduledoc """
  This module reads from an infinite [server-sent events](https://en.wikipedia.org/wiki/Server-sent_events)
  stream with information about edits and other changes to all Wikimedia
  projects.
  
  For more about the public wiki streams and their format, see
  [EventStreams on Wikitech](https://wikitech.wikimedia.org/wiki/EventStreams)

  ## Application parameters

  * endpoint: URL to the SSE feed
  * event_callback: Callback taking one argument, the event message.

  ## Event callback

  The event callback should accept an EventsourceEx.Message.  It will be
  executed in its own linked task, so only raise an error if you intend to stop
  the application.
  """

  @sse_feed "https://stream.wikimedia.org/v2/stream/recentchange"

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
        Task.start_link(fn ->
          event_callback.(message)
        end)
    end
    watch_feed(event_callback)
  end

  @doc """
  Example callback prints a summary of each message.
  """
  def demo_event_callback(message) do
    data = Poison.decode!(message.data)
    case data["type"] do
      "categorize" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} #{data["comment"]} as #{data["title"]} by #{data["user"]})
      "edit" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} edited by #{data["user"]})
      "log" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} #{data["log_action"]} by #{data["user"]})
      "new" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} created by #{data["user"]})
      _ ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["type"]} event: #{message.data})
    end
  end
end
