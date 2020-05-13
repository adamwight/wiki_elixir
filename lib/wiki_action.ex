defmodule WikiAction do
  # TODO: These should come from the environment, etc.
  @username Application.get_env(:wiki_elixir, :username)
  @password Application.get_env(:wiki_elixir, :password)
  @endpoint Application.get_env(:wiki_elixir, :action_api)

  # TODO: discover API endpoint from wiki domain.
  @spec get(map()) :: map()
  def get(params) do
    # FIXME: underride as defaults
    params = Map.put(params, :format, :json)

    # FIXME: support a base URL with prepended parameters, see HTTPoison.Base.build_query_params
    url = @endpoint <> "?" <> URI.encode_query(params)
    {:ok, response} = Mojito.get(url)
    response.body
      |> Jason.decode!
  end
end
