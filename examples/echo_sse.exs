# mix run ./examples/echo_sse.ex

defmodule Source do
  def start_link() do
    WikiSSE.start_link()
  end
end

defmodule Consumer do
  use ConsumerSupervisor

  def start_link() do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    ConsumerSupervisor.init([Echo], strategy: :one_for_one, subscribe_to: [Source])
  end
end

defmodule Echo do
  use GenServer

  def start_link(message) do
    Task.start_link(fn ->
      DebugMessage.echo_event(message)
    end)
  end

  def init(message) do
    {:ok, message}
  end

  def child_spec(message) do
    %{
      id: __MODULE__,
      restart: :transient,
      start: {__MODULE__, :start_link, [message]}
    }
  end
end

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

defmodule App do
  def start do
    children = [
      %{
        id: Source,
        start: {Source, :start_link, []}
      },
      %{
        id: Consumer,
        start: {Consumer, :start_link, []}
      }
    ]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  end
end

App.start()
Process.sleep(:infinity)
