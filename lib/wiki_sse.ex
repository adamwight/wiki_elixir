defmodule WikiSSE do
  @moduledoc """
  This module reads from an infinite stream of [server-sent events](https://en.wikipedia.org/wiki/Server-sent_events)
  annotating actions such as editing or patrolling, as they happen on Wikimedia projects.

  For more about the public wiki streams and their format, see
  [EventStreams on Wikitech](https://wikitech.wikimedia.org/wiki/EventStreams)
  """
  use GenStage

  def start_link(endpoint \\ default_endpoint()) do
    # FIXME: run under a supervisor tree
    # TODO: extract this specific line, the rest is an adapter between raw received -> queue -> genstage producer.
    EventsourceEx.new(endpoint, headers: [])

    GenStage.start_link(__MODULE__, [])
  end

  def init([]) do
    queue = :queue.new()
    {:producer, queue}
  end

  @spec handle_info(map(), queue())
  def handle_info(message, queue) do
    queue1 = :queue.in(message, queue)
    {:noreply, queue1}
  end

  @spec handle_demand(integer(), queue())
  def handle_demand(demand, queue) do
    demand1 = min(demand, :queue.len(queue))
    {retrieved, queue1} = :queue.split(demand1, queue)
    retrieved1 = retrieved |> :queue.reverse |> :queue.to_list
    {:noreply, retrieved1, queue1}
  end

  defp default_endpoint() do
    Application.get_env(:wiki_elixir, :sse_feed)
  end
end
