# mix run ./examples/echo_sse.exs

defmodule DebugMessage do
  @spec echo_event(map()) :: String.t()
  def echo_event(message) do
    message
      |> event_line
      |> IO.puts
  end

  defp event_line(data) do
    [data["meta"]["dt"], ": ", :green, data["wiki"], :reset, " ", summarize_event(data)]
      |> IO.ANSI.format()
  end

  defp summarize_event(%{"type" => "categorize"} = data) do
    ~s(#{data["title"]} #{data["comment"]} as #{data["title"]} by #{data["user"]})
  end

  defp summarize_event(%{"type" => "edit"} = data) do
    ~s(#{data["title"]} edited by #{data["user"]})
  end

  defp summarize_event(%{"type" => "log"} = data) do
    ~s(#{data["title"]} #{data["log_action"]} by #{data["user"]})
  end

  defp summarize_event(%{"type" => "new"} = data) do
    ~s(#{data["title"]} created by #{data["user"]})
  end

  defp summarize_event(data) do
    data["type"] <> " event: " <> Poison.encode!(data)
  end
end

WikiSSE.start_link()
WikiSSE.stream()
  |> Stream.map(fn message -> DebugMessage.echo_event(message) end)
  |> Stream.run()
