defmodule WikiAction do
  # TODO: These should come from the environment, etc.
  # TODO: discover API endpoint from wiki domain.
  # FIXME: underride format: :json, etc. as defaults
  @username Application.get_env(:wiki_elixir, :username)
  @password Application.get_env(:wiki_elixir, :password)
  @endpoint Application.get_env(:wiki_elixir, :action_api)

  @spec stream(map()) :: Enumerable.t()
  def stream(params) do
    Stream.resource(
      fn -> get(params) end,
      fn prev ->
        case prev do
          %{"continue" => continue} ->
            next = get(
              Map.merge(params, continue)
            )
            {[next], next}

          _ ->
            {:halt, nil}
        end
      end,
      fn _ -> end
    )
  end

  @spec get(map()) :: map()
  def get(params) do
    # FIXME: support a base URL with prepended parameters, see HTTPoison.Base.build_query_params
    url = @endpoint <> "?" <> URI.encode_query(params)
    {:ok, response} = Mojito.get(url)
    response.body
      |> Jason.decode!
  end
end
