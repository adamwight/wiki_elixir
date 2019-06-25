defmodule Ui do
  def init() do
    #ExNcurses.initscr()

    :ets.new(:counters, [:named_table])
    :ets.insert_new(:counters, {"api_calls", 0})
  end

  def incrementApiCalls() do
    :ets.update_counter(:counters, "api_calls", 1)
    |> IO.puts
    #|> ExNcurses.printw
  end

  def refresh() do
    #ExNcurses.refresh()
  end

  # TODO: wire to atexit
  def stop() do
    ExNcurses.endwin()
  end
end
