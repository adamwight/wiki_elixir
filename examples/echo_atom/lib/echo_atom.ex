defmodule EchoAtom do
  def start(:normal, []) do
    WikiRecentChangesFeed.start_link(&EchoAtom.demo_edit_line/1)
  end

  @doc """
  Print edit lines to stdout.
  """
  def demo_edit_line({_, author, _, _, _, diff_url, _, _, _, _html, title, timestamp}) do
    IO.puts "#{timestamp}: #{author} edited #{title}: #{diff_url}"
  end
end
