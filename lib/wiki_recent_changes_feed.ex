defmodule WikiRecentChangesFeed do
  @moduledoc """
  Wikipedia's built-in Recent Changes feed allows us to poll up to 50 recent
  edits at a time.  This module applies a callback to each edit.
  """

  @type recent_change :: map()
  @type change_event_sink :: (recent_change -> none())

  @spec start_link(change_event_sink) :: {:ok, pid()}
  def start_link(edit_callback) do
    # FIXME: use a GenStage, etc.
    Task.start_link(__MODULE__, :parse_atom, [edit_callback])
  end

  defp atom_params() do
    %{
      action: :feedrecentchanges,
      days: 7,
      feedformat: :atom,
      limit: 50,
      hidebots: 1,
      hidecategorization: 1,
      hideWikibase: 1,
      urlversion: 1,
    }
  end

  @spec parse_atom(change_event_sink) :: nil
  def parse_atom(edit_callback) do
    # TODO: XML variant of WikiAction.stream
    WikiAction.get(atom_params())
    |> :feeder.stream(initial_opts(edit_callback))
  end

  @spec initial_opts(change_event_sink) :: [...]
  defp initial_opts(edit_callback) do
    [
      event_state: {nil, []},
      event_fun: &WikiRecentChangesFeed.event(&1, &2, edit_callback)
    ]
  end

  @spec event({:entry, recent_change}, {:feeder.feed(), [recent_change, ...]}, change_event_sink) ::
          {:feeder.feed(), [recent_change, ...]}
  def event({:entry, entry}, {feed, entries}, edit_callback) do
    Task.start_link(fn ->
      edit_callback.(entry)
    end)

    # Accumulate the results out of habit, although we'll probably throw it out later.
    {feed, [entry] ++ entries}
  end

  @spec event({:feed, :feeder.feed()}, {nil, [recent_change, ...]}, change_event_sink) ::
          {:feeder.feed(), [recent_change, ...]}
  def event({:feed, feed}, {nil, entries}, _) do
    {feed, entries}
  end

  @spec event(:endFeed, {:feeder.feed(), [recent_change, ...]}, any()) ::
          {:feeder.feed(), [recent_change, ...]}
  def event(:endFeed, {feed, entries}, _) do
    {feed, Enum.reverse(entries)}
  end
end
