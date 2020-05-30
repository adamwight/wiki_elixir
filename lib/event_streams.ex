defmodule Wiki.EventStreams do
  @moduledoc """
  This module reads from an infinite stream of [server-sent events](https://en.wikipedia.org/wiki/Server-sent_events)
  annotating actions such as editing or patrolling, as they happen on Wikimedia projects.

  For more about the public wiki streams and their format, see
  [EventStreams on Wikitech](https://wikitech.wikimedia.org/wiki/EventStreams)

  ## Examples

  Start reading the page creation feed, and expose as a GenStage.stream:

  ```elixir
  Wiki.EventStreams.start_link(streams: "page-create")
  Wiki.EventStreams.stream()
  |> Stream.take(6)
  |> Enum.to_list
  |> IO.inspect
  ```

  Combine multiple feeds,

  ```elixir
  Wiki.EventStreams.start_link(streams: ["revision-create", "revision-score"])
  Wiki.EventStreams.stream()
  |> Stream.take(6)
  |> Enum.to_list
  |> IO.inspect
  ```

  ## TODO

  * Currently only a single supervisor tree is supported, so calling applications can only read from one stream.
  * Track the restart ID, disconnect from the feed at some maximum queue size.  Reconnect as demand resumes.
  Application-lifetime or permanent storage for the restart ID tracking, for consumers that need an at-least-once
  guarantee.
  """

  defmodule Relay do
    @moduledoc false

    use GenStage

    @type state :: {:queue.queue(), integer}

    @type reply :: {:noreply, [map], state}

    @spec start_link(keyword) :: GenServer.on_start()
    def start_link(args) do
      GenStage.start_link(__MODULE__, args, name: __MODULE__)
    end

    @impl true
    @spec init(any) :: {:producer, state}
    def init(_) do
      {:producer, {:queue.new(), 0}}
    end

    @impl true
    @spec handle_info(EventsourceEx.Message.t(), state) :: reply
    def handle_info(message, {queue, pending_demand}) do
      event = decode_message_data(message)
      queue1 = :queue.in(event, queue)
      # FIXME: Suppress reply until above min_demand or periodic timeout has elapsed.
      dispatch_events(queue1, pending_demand)
    end

    @impl true
    @spec handle_demand(integer, state) :: reply
    def handle_demand(demand, {queue, pending_demand}) do
      dispatch_events(queue, demand + pending_demand)
    end

    @spec dispatch_events(:queue.queue(), integer) :: reply
    defp dispatch_events(queue, demand) do
      available = min(demand, :queue.len(queue))
      {retrieved, queue1} = :queue.split(available, queue)
      events = :queue.to_list(retrieved) |> Enum.reverse()
      {:noreply, events, {queue1, demand - available}}
    end

    @spec decode_message_data(EventsourceEx.Message.t()) :: map
    defp decode_message_data(message) do
      message.data
      |> Jason.decode!()
    end
  end

  defmodule Source do
    @moduledoc false

    alias Wiki.Util

    @spec child_spec(String.t()) :: map
    def child_spec(endpoint) do
      headers = [
        {"user-agent", Util.user_agent()}
      ]

      %{
        id: Source,
        # FIXME: nicer if we could get the Relay sibling's specific PID each time,
        #  to allow an app to use multiple stream listeners.
        start: {
          EventsourceEx,
          :new,
          [
            endpoint,
            [
              adapter: Application.get_env(:wiki_elixir, :eventsource_adapter),
              headers: headers,
              stream_to: Relay
            ]
          ]
        }
      }
    end
  end

  defmodule RelaySupervisor do
    @moduledoc false

    use Supervisor, restart: :permanent

    alias Wiki.EventStreams

    @spec start_link(keyword) :: GenServer.on_start()
    def start_link(args) do
      endpoint = args[:endpoint] || EventStreams.default_endpoint()
      url = endpoint <> normalize_streams(args[:streams])
      sink = args[:send_to] || self()

      children = [
        {Relay, sink},
        {Source, url}
      ]

      {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
    end

    @impl true
    def init(args) do
      {:ok, args}
    end

    @spec normalize_streams(atom | [atom]) :: atom | String.t()
    defp normalize_streams(streams)

    defp normalize_streams(streams) when is_list(streams), do: Enum.join(streams, ",")

    defp normalize_streams(streams), do: streams
  end

  @type options :: [option]

  @type option ::
          {:endpoint, String.t()}
          | {:send_to, GenServer.server()}
          | {:streams, atom | [atom]}

  @doc """
  Start a supervisor tree to receive and relay server-side events.

  ## Arguments

  - `options` - Keyword list,
    - `{:endpoint, url}` - Override default endpoint.
    - `{:send_to, pid | module}` - Instead of using the built-in streaming relay,
    send the events directly to your own process.
    - `{:streams, atom | [atom]}` - Select which streams to listen to.  An updated list can be
    [found here](https://stream.wikimedia.org/?doc#/Streams).  Required.
  """
  @spec start_link(options) :: GenServer.on_start()
  def start_link(args) do
    RelaySupervisor.start_link(args)
  end

  @doc """
  Capture subscribed events and relay them as a `Stream`.
  """
  @spec stream(keyword) :: Enumerable.t()
  def stream(options \\ []) do
    GenStage.stream([Relay], options)
  end

  @doc false
  @spec default_endpoint() :: String.t()
  def default_endpoint do
    "https://stream.wikimedia.org/v2/stream/"
  end
end
