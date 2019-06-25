defmodule Counters do
  def init() do
    :ets.new(:counters, [:named_table, :public])
    :ets.insert_new(:counters, [api_calls: 0])
  end

  def incrementApiCalls() do
    :ets.update_counter(:counters, :api_calls, 1)
  end

  def getApiCalls() do
    [api_calls: count] = :ets.lookup(:counters, :api_calls)
    count
  end
end
