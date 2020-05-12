# mix run ./examples/echo_sse.exs

defmodule DebugMessage do
  def echo_event(message) do
    message
      |> decode_message_data
      |> event_line
      |> IO.puts
  end

  defp decode_message_data(message) do
    message.data
      |> Poison.decode!
  end

  defp event_line(data) do
    data["meta"]["dt"] <> ": " <> summarize_event(data)
  end

  defp summarize_event(%{"type" => "categorize"} = data) do
    ~s(#{data["wiki"]} #{data["title"]} #{data["comment"]} as #{data["title"]} by #{data["user"]})
  end

  defp summarize_event(%{"type" => "edit"} = data) do
    ~s(#{data["wiki"]} #{data["title"]} edited by #{data["user"]})
  end

  defp summarize_event(%{"type" => "log"} = data) do
    ~s(#{data["wiki"]} #{data["title"]} #{data["log_action"]} by #{data["user"]})
  end

  defp summarize_event(%{"type" => "new"} = data) do
    ~s(#{data["wiki"]} #{data["title"]} created by #{data["user"]})
  end

  defp summarize_event(data) do
    data["type"] <> " event: " <> Poison.encode!(data)
  end
end

WikiSSE.RelaySupervisor.start_link([])

GenStage.stream([WikiSSE.Relay])
  |> Stream.map(fn message -> DebugMessage.echo_event(message) end)
  |> Stream.run()
