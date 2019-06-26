defmodule Ui do
  use Agent

  @refresh_interval Application.get_env(:trending_edits, :ui_refresh_interval)

  def start_link(_opts) do
    ExNcurses.initscr()

    :timer.apply_interval(@refresh_interval, Ui, :paint, [])

    Agent.start_link(fn -> %{} end)
  end

  # TODO: break up repaint by window
  def paint() do
    ExNcurses.move(0, 0)
    count = Counters.getApiCalls()
    ExNcurses.printw("Total API calls: " <> Integer.to_string(count))

    # TODO: show all, scroll
    TrendStore.getArticles()
    |> paint_articles

    refresh()
  end

  def paint_articles(article_list) do
    ExNcurses.move(1, 0)
    ExNcurses.printw "Trending articles receiving edits:"

    unless article_list == [] do
      article_list
      |> Enum.with_index
      |> Enum.each(fn({line, y}) ->
          ExNcurses.move(2 + y, 0)
          line
          |> Poison.encode!
          |> ExNcurses.printw
          # TODO: stop before end of window
      end)
    end
  end

  def refresh() do
    ExNcurses.refresh()
  end

  # TODO: wire to atexit
  def stop() do
    ExNcurses.endwin()
  end
end
