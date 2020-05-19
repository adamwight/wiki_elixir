defmodule Wiki.EventStreams do
  @moduledoc """
  This module reads from an infinite stream of [server-sent events](https://en.wikipedia.org/wiki/Server-sent_events)
  annotating actions such as editing or patrolling, as they happen on Wikimedia projects.

  For more about the public wiki streams and their format, see
  [EventStreams on Wikitech](https://wikitech.wikimedia.org/wiki/EventStreams)

  ## Examples

  Start reading the default feed, and expose as a GenStage.stream:

    Wiki.EventStreams.start_link()
    Wiki.EventStreams.stream() |> Stream.take(6) |> Enum.to_list |> IO.inspect

  ## TODO

  * Track the restart ID, disconnect from the feed at some maximum queue size.  Reconnect as demand resumes.
  Application-lifetime or permanent storage for the restart ID tracking, for consumers that need an at-least-once
  guarantee.
  """

  defmodule Relay do
    use GenStage

    @type state :: {:queue.queue(), integer}

    @type reply :: {:noreply, [map()], state()}

    def start_link(args) do
      GenStage.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(_) do
      {:producer, {:queue.new(), 0}}
    end

    @spec handle_info(EventsourceEx.Message.t(), state()) :: reply()
    def handle_info(message, {queue, pending_demand}) do
      event = decode_message_data(message)
      queue1 = :queue.in(event, queue)
      # FIXME: Suppress reply until above min_demand or periodic timeout has elapsed.
      dispatch_events(queue1, pending_demand)
    end

    @spec handle_demand(integer(), state()) :: reply()
    def handle_demand(demand, {queue, pending_demand}) do
      dispatch_events(queue, demand + pending_demand)
    end

    defp dispatch_events(queue, demand) do
      available = min(demand, :queue.len(queue))
      {retrieved, queue1} = :queue.split(available, queue)
      events = :queue.to_list(retrieved) |> Enum.reverse()
      {:noreply, events, {queue1, demand - available}}
    end

    @spec decode_message_data(EventsourceEx.Message.t()) :: map()
    defp decode_message_data(message) do
      message.data
      |> Jason.decode!()
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

  @type options :: [option]

  @type option ::
          {:endpoint, String.t()}
          | {:send_to, GenServer.server()}

  @spec start_link(options) :: GenServer.on_start()
  def start_link(args \\ []) do
    RelaySupervisor.start_link(args)
  end

  @spec stream(keyword) :: Enumerable.t()
  def stream(options \\ []) do
    GenStage.stream([Relay], options)
  end
end
