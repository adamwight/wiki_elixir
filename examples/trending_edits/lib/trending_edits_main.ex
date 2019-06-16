# FIXME: YAGNI extra layers of application cruft?

defmodule TrendingEditsApplication do
  use Application

  def start(_type, _args) do
    TrendingEditsSupervisor.start_link(name: TrendingEditsSupervisor)
  end
end

defmodule TrendingEditsSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    # TODO: LRU cache for recent articles
    children = [
        TrendingEditsMain
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TrendingEditsMain do
  def start(:normal, []) do
    WikiSSE.start_link(&receive_event/1)
  end

  def receive_event(event) do
    event
    |> decode_message_data
    |> merge_pageviews
    |> Stream.filter(&trending?/1)
    |> Enum.to_list
    |> summarize_line
    |> IO.inspect
  end

  def decode_message_data(message) do
    message.data
    |> Poison.decode!
  end

  def merge_pageviews(data) do
    # TODO: dynamic timestamps, configurable window
    history = WikiRest.pageviews(data["server_name"], title_safe(data["title"]), "20190612", "20190617")
    # TODO: strip REST cruft?
    case history do
      %{:items => items} ->
        Map.merge(data, %{pageviews: items})
      _ ->
        data
    end
  end

  def title_safe(title) do
    # TODO: spaces to underscores, percent-encode some crap
    title
  end

  def trending?(data) do
    case data do
      %{:pageviews => views} ->
        views[-1]["views"] > 2 * views[0]["views"]
      _ ->
        false
    end
  end

  def summarize_line(data) do
    ~s(#{data[:title]}; views jumped #{data[:pageviews][0][:views]} -> #{data[:pageviews][-1][:views]})
  end
end
