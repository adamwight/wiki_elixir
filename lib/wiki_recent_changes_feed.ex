defmodule WikiRecentChangesFeed do
  @moduledoc """
  Wikipedia's built-in Recent Changes feed allows us to poll up to 50 recent
  edits at a time.  This module applies a callback to each edit.
  """

  @recent_changes_feed "https://en.wikipedia.org/w/api.php?hidebots=1&hidecategorization=1&hideWikibase=1&urlversion=1&days=7&limit=50&action=feedrecentchanges&feedformat=atom"

  @type RecentChange :: [...]
  @type EventSink :: (RecentChange -> none())

  @spec start_link(EventSink, String.t()) :: on_start()
  def start_link(edit_callback, endpoint \\ @recent_changes_feed) do
    Task.start_link(__MODULE__, :parse_atom, [edit_callback, endpoint])
  end

  @spec atom_response(String.t()) :: HTTPoison.AsyncResponse.t()
  defp atom_response(endpoint) do
    HTTPoison.get!(endpoint)
  end

  @spec atom_content(String.t()) :: HTTPoison.AsyncResponse.t()
  defp atom_content(endpoint) do
    atom_response(endpoint).body
  end

  @spec parse_atom(EventSink, String.t()) :: nil
  defp parse_atom(edit_callback, endpoint) do
    :feeder.stream(atom_content(endpoint), initial_opts(edit_callback))
  end

  @spec initial_opts(EventSink) :: [...]
  defp initial_opts(edit_callback) do
    [
      event_state: {nil, []},
      event_fun: &WikiRecentChangesFeed.event(&1, &2, edit_callback)
    ]
  end

  @spec event({:entry, RecentChange}, {:feeder.feed(), [RecentChange, ...]}, EventSink) ::
          {:feeder.feed(), [RecentChange, ...]}
  defp event({:entry, entry}, {feed, entries}, edit_callback) do
    Task.start_link(fn ->
      edit_callback.(entry)
    end)

    # Accumulate the results out of habit, although we'll probably throw it out later.
    {feed, [entry] ++ entries}
  end

  @spec event({:feed, :feeder.feed()}, {nil, [RecentChange, ...]}, EventSink) ::
          {:feeder.feed(), [RecentChange, ...]}
  def event({:feed, feed}, {nil, entries}, _) do
    {feed, entries}
  end

  @spec event(:endFeed, {:feeder.feed(), [RecentChange, ...]}, any()) ::
          {:feeder.feed(), [RecentChange, ...]}
  def event(:endFeed, {feed, entries}, _) do
    {feed, Enum.reverse(entries)}
  end
end
