defmodule Ui do
  def init() do
    ExNcurses.initscr()

    :ets.new(:counters, [:named_table, :public])
    :ets.insert_new(:counters, {"api_calls", 0})
  end

  def incrementApiCalls() do
    ExNcurses.move(0, 0)
    count = :ets.update_counter(:counters, "api_calls", 1)

    ExNcurses.printw("Total API calls: " <> Integer.to_string(count))
  end

  def refresh() do
    ExNcurses.refresh()
  end

  # TODO: wire to atexit
  def stop() do
    ExNcurses.endwin()
  end
end
