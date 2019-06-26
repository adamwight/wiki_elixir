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
        Counters,
        TrendingEditsMain,
        TrendStore,
        Ui,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TrendingEditsMain do
  use Agent

  def start_link(_opts) do
    WikiSSE.start_link(&receive_event/1)
    # TODO: progress thread showing number of matches attempted and API requests

    Agent.start_link(fn -> %{} end)
  end

  def receive_event(event) do
    event
    |> decode_message_data
    |> merge_pageviews
    |> print_when_trending

    Counters.incrementApiCalls()
  end

  def print_when_trending(event) do
    # FIXME: `if` is a smell?
    # FIXME: only report uniques
    if trending?(event) do
      event
      |> store_trend
    end
  end

  def decode_message_data(message) do
    message.data
    |> Poison.decode!
  end

  def merge_pageviews(data) do
    # TODO: configurable time window
    history = WikiRest.Pageviews.pageviews_per_article(data["server_name"], title_safe(data["title"]))
    # TODO: strip REST cruft?
    case history do
      %{"items" => items} ->
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
    # TODO:
    # * 2 or more editors
    case data do
      %{:pageviews => views} ->
        %{"views" => old_views} = hd(Enum.reverse(views))
        %{"views" => new_views} = hd(views)
        #~s(#{hd(views)[:views]} -> #{tl(views)[:views]} (#{tl(views)[:views] / hd(views)[:views] - 1.0}%\))
        old_views * 2 < new_views && new_views > 1_000
      _ ->
        false
    end
  end

  def store_trend(data) do
    # FIXME: DRY
    %{:pageviews => views, "title" => title} = data
    %{"views" => old_views} = hd(Enum.reverse(views))
    %{"views" => new_views} = hd(views)
    TrendStore.insertArticle(title, old_views, new_views)
  end

  def summarize_line(data) do
    # FIXME: DRY
    %{:pageviews => views, "title" => title} = data
    %{"views" => old_views} = hd(Enum.reverse(views))
    %{"views" => new_views} = hd(views)
    ~s(#{title}; views jumped #{old_views} -> #{new_views})
  end
end
