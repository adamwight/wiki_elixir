defmodule WikiRecentChangesFeed do
  @moduledoc """
  Wikipedia's built-in Recent Changes feed allows us to poll up to 50 recent
  edits at a time.  This module applies a callback to each edit.  The default
  callback is for demonstration, and will print a summary of each edit, one per
  line.
  """

  @recent_changes_feed "https://en.wikipedia.org/w/api.php?hidebots=1&hidecategorization=1&hideWikibase=1&urlversion=1&days=7&limit=50&action=feedrecentchanges&feedformat=atom"

  def start_link(edit_callback, endpoint \\ @recent_changes_feed) do
    Task.start_link(fn ->
      parse_atom(edit_callback, endpoint)
    end)
  end

  defp atom_response(endpoint) do
    HTTPotion.get endpoint
  end

  defp atom_content(endpoint) do
    atom_response(endpoint).body
  end

  defp parse_atom(edit_callback, endpoint) do
    :feeder.stream atom_content(endpoint), initial_opts(edit_callback)
  end

  defp initial_opts(edit_callback) do
    [
      event_state: {nil, []},
      event_fun: &WikiRecentChangesFeed.event(&1, &2, edit_callback)
    ]
  end

  @doc false
  def event({:entry, entry}, {feed, entries}, edit_callback) do
    Task.start_link(fn ->
      edit_callback.(entry)
    end)
    # Accumulate the results out of habit, although we'll probably throw it out later.
    {feed, [entry] ++ entries}
  end

  def event({:feed, feed}, {nil, entries}, _) do
    {feed, entries}
  end

  def event(:endFeed, {feed, entries}, _) do
    {feed, Enum.reverse(entries)}
  end
end
