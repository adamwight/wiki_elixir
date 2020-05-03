defmodule WikiRecentChangesFeed do
  @moduledoc """
  Wikipedia's built-in Recent Changes feed allows us to poll up to 50 recent
  edits at a time.  This module applies a callback to each edit.
  """

  @recent_changes_feed "https://en.wikipedia.org/w/api.php?hidebots=1&hidecategorization=1&hideWikibase=1&urlversion=1&days=7&limit=50&action=feedrecentchanges&feedformat=atom"

  @type recent_change :: map()
  @type change_event_sink :: (recent_change -> none())

  @spec start_link(change_event_sink, String.t()) :: {:ok, pid()}
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

  @spec parse_atom(change_event_sink, String.t()) :: nil
  defp parse_atom(edit_callback, endpoint) do
    :feeder.stream(atom_content(endpoint), initial_opts(edit_callback))
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
  defp event({:entry, entry}, {feed, entries}, edit_callback) do
    Task.start_link(fn ->
      edit_callback.(entry)
    end)

    # Accumulate the results out of habit, although we'll probably throw it out later.
    {feed, [entry] ++ entries}
  end

  @spec event({:feed, :feeder.feed()}, {nil, [recent_change, ...]}, change_event_sink) ::
          {:feeder.feed(), [recent_change, ...]}
  defp event({:feed, feed}, {nil, entries}, _) do
    {feed, entries}
  end

  @spec event(:endFeed, {:feeder.feed(), [recent_change, ...]}, any()) ::
          {:feeder.feed(), [recent_change, ...]}
  defp event(:endFeed, {feed, entries}, _) do
    {feed, Enum.reverse(entries)}
  end
end
