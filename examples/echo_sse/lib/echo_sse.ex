defmodule EchoSSE do
  def start(:normal, []) do
    WikiSSE.start_link(&EchoSSE.echo_event/1)
  end

  @doc """
  Example callback prints a summary of each message.
  """
  def echo_event(message) do
    data = Poison.decode!(message.data)
    case data["type"] do
      "categorize" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} #{data["comment"]} as #{data["title"]} by #{data["user"]})
      "edit" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} edited by #{data["user"]})
      "log" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} #{data["log_action"]} by #{data["user"]})
      "new" ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["wiki"]} #{data["title"]} created by #{data["user"]})
      _ ->
        IO.puts ~s(#{data["meta"]["dt"]}: #{data["type"]} event: #{message.data})
    end
  end
end
