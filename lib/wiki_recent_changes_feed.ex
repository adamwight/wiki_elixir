defmodule WikiRecentChangesFeed do
  @moduledoc """
  Wikipedia's built-in Recent Changes feed allows us to poll up to 50 recent
  edits at a time.  This module applies a callback to each edit.  The default
  callback is for demonstration, and will print a summary of each edit, one per
  line.
  """

  @recent_changes_feed "https://en.wikipedia.org/w/api.php?hidebots=1&hidecategorization=1&hideWikibase=1&urlversion=1&days=7&limit=50&action=feedrecentchanges&feedformat=atom"

  @doc """
  """
  def start(:normal, []) do
    start(:normal, [@recent_changes_feed, &WikiRecentChangesFeed.demo_edit_line/1])
  end

  def start(:normal, [endpoint, edit_callback]) do
    Task.start_link(fn ->
      parse_atom(endpoint, edit_callback)
    end)
  end

  def atom_response(endpoint) do
    HTTPotion.get endpoint
  end

  def atom_content(endpoint) do
    atom_response(endpoint).body
  end

  defp parse_atom(endpoint, edit_callback) do
    :feeder.stream atom_content(endpoint), initial_opts(edit_callback)
  end

  defp initial_opts(edit_callback) do
    [
      event_state: {nil, []},
      event_fun: &WikiRecentChangesFeed.event(&1, &2, edit_callback)
    ]
  end

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

  def demo_edit_line({_, author, _, _, _, diff_url, _, _, _, _html, title, timestamp}) do
    IO.puts "#{timestamp}: #{author} edited #{title}: #{diff_url}"
  end
end
