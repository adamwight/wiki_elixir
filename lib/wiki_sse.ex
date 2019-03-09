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

  def start_link(event_callback) do
    # TODO: needs a supervisor
    watcher = Task.start_link(fn ->
      watch_feed(event_callback)
    end)
    # TODO: make the feed URL configurable
    read_feed(@sse_feed, elem(watcher, 1))
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
end
