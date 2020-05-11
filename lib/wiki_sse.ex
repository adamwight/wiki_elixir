defmodule WikiSSE do
  @moduledoc """
  This module reads from an infinite stream of [server-sent events](https://en.wikipedia.org/wiki/Server-sent_events)
  annotating actions such as editing or patrolling, as they happen on Wikimedia projects.

  For more about the public wiki streams and their format, see
  [EventStreams on Wikitech](https://wikitech.wikimedia.org/wiki/EventStreams)

  TODO:
  * Track the restart ID
  * Expose the restart ID?
  * Use the restart ID internally and reconnect from that point.
  * Application-lifetime or permanent storage for message queue, or restart ID tracking, for consumers that need an at-least-once guarantee.
  """

  defmodule Relay do
    use GenStage

    def start_link(args) do
      GenStage.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(_) do
      {:producer, :queue.new()}
    end

    @spec handle_info(map(), :queue.queue()) :: {:noreply, [], :queue.queue()}
    def handle_info(message, queue) do
      queue1 = :queue.in(message, queue)
      {:noreply, [], queue1}
    end

    @spec handle_demand(integer(), :queue.queue()) :: {:noreply, list(), :queue.queue()}
    def handle_demand(demand, queue) when demand > 0 do
      demand1 = min(demand, :queue.len(queue))
      {retrieved, queue1} = :queue.split(demand1, queue)
      retrieved1 = retrieved |> :queue.reverse() |> :queue.to_list()
      {:noreply, retrieved1, queue1}
    end
  end

  defmodule Source do
    def child_spec(endpoint) do
      %{
        id: Source,
        # FIXME: nicer if we could get the Relay sibling's specific PID each time, to allow an app to use multiple stream listeners.
        start: {EventsourceEx, :new, [endpoint, [headers: [], stream_to: Relay]]}
      }
    end
  end

  defmodule RelaySupervisor do
    use Supervisor, restart: :permanent

    def init(args) do
      {:ok, args}
    end

    def start_link(args) do
      endpoint = args[:endpoint] || default_endpoint()
      sink = args[:send_to] || self()

      children = [
        {Relay, sink},
        {Source, endpoint}
      ]

      {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
    end

    # FIXME: Define in top-level module--why does this make it inaccessible here?
    defp default_endpoint() do
      Application.get_env(:wiki_elixir, :sse_feed)
    end
  end
end
