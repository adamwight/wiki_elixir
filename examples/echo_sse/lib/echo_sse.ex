defmodule EchoSSE do
  def start(:normal, []) do
    WikiSSE.start_link(&echo_event/1)
  end

  @doc """
  Example callback prints a summary of each message.
  """
  def echo_event(message) do
    message
    |> decode_message_data
    |> summarize_event
    |> IO.puts
  end

  def decode_message_data(message) do
    message.data
    |> Poison.decode!
  end

  def summarize_event(data) do
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
