defmodule WikiSSE do
  @moduledoc """
  This module reads from an infinite stream of [server-sent events](https://en.wikipedia.org/wiki/Server-sent_events)
  annotating actions such as editing or patrolling, as they happen on Wikimedia projects.

  For more about the public wiki streams and their format, see
  [EventStreams on Wikitech](https://wikitech.wikimedia.org/wiki/EventStreams)
  """

  @sse_feed "https://stream.wikimedia.org/v2/stream/recentchange"

  @doc """
  Begin reading from the feed.

  ## Parameters

  * event_callback: Callback taking one argument, the event message.
  * endpoint: URL to the SSE feed

  ## Event callback

  The event callback should accept an EventsourceEx.Message.  It will be
  executed in its own linked task, so only raise an error if you intend to stop
  the application.  message.data is a JSON-encoded payload.
  """
  def start_link(event_callback, endpoint \\ @sse_feed) do
    # TODO: needs a supervisor
    watcher = Task.start_link(fn ->
      watch_feed(event_callback)
    end)
    # TODO: make the feed URL configurable
    read_feed(elem(watcher, 1), endpoint)
  end

  defp read_feed(watcher, endpoint) do
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
end
