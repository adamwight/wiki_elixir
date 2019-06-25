defmodule Ui do
  @refresh_interval 1_000

  def init() do
    ExNcurses.initscr()

    :timer.apply_interval(@refresh_interval, Ui, :paint, [])
  end

  # TODO: break up repaint by window
  def paint() do
    ExNcurses.move(0, 0)
    count = Counters.getApiCalls()
    ExNcurses.printw("Total API calls: " <> Integer.to_string(count))

    refresh()
  end

  def refresh() do
    ExNcurses.refresh()
  end

  # TODO: wire to atexit
  def stop() do
    ExNcurses.endwin()
  end
end
