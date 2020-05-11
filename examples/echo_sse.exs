# mix run ./examples/echo_sse.exs

defmodule DebugMessage do
  def echo_event(message) do
    message
    |> decode_message_data
    |> summarize_event
    |> IO.puts
  end

  defp decode_message_data(message) do
    message.data
    |> Poison.decode!
  end

  defp summarize_event(data) do
    case data["type"] do
      "categorize" ->
        ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} #{data["comment"]} as #{data["title"]} by #{data["user"]})
      "edit" ->
        ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} edited by #{data["user"]})
      "log" ->
        ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} #{data["log_action"]} by #{data["user"]})
      "new" ->
        ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} created by #{data["user"]})
      _ ->
        ~s(#{data["meta"]["dt"]}: #{data["type"]} event: #{Poison.encode!(data)})
    end
  end
end

WikiSSE.RelaySupervisor.start_link([])

GenStage.stream([WikiSSE.Relay])
  |> Stream.map(fn message -> DebugMessage.echo_event(message) end)
  |> Stream.run()
