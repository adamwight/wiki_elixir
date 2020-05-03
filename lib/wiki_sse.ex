defmodule WikiSSE do
  @moduledoc """
  This module reads from an infinite stream of [server-sent events](https://en.wikipedia.org/wiki/Server-sent_events)
  annotating actions such as editing or patrolling, as they happen on Wikimedia projects.

  For more about the public wiki streams and their format, see
  [EventStreams on Wikitech](https://wikitech.wikimedia.org/wiki/EventStreams)
  """

  @sse_feed "https://stream.wikimedia.org/v2/stream/recentchange"

  @type message_sink :: (EventsourceEx.Message.t -> none())

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
  @spec start_link(message_sink, String.t()) :: {:ok, pid()}
  def start_link(event_callback, endpoint \\ @sse_feed) do
    # TODO: needs a supervisor
    {:ok, watcher} =
      Task.start_link(fn ->
        watch_feed(event_callback)
      end)

    # TODO: make the feed URL configurable
    read_feed(watcher, endpoint)
  end

  @spec read_feed(pid(), String.t()) :: {:ok, pid()}
  defp read_feed(watcher, endpoint) do
    EventsourceEx.new(endpoint, headers: [], stream_to: watcher)
  end

  @spec watch_feed(message_sink) :: none()
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
