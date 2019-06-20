defmodule WikiAction do
  @username Application.get_env(:wiki_elixir, :username)
  @password Application.get_env(:wiki_elixir, :password)

  # TODO: discover API endpoint from wiki domain.
  def request(endpoint, params) do
    # FIXME: underride as defaults
    params = Map.put(params, :format, :json)
    build_query(endpoint, params)
    |> HTTPoison.get!
    |> extract_body
  end

  defp build_query(endpoint, params) do
    endpoint <> "?" <> URI.encode_query(params)
  end

  defp extract_body(response) do
    response.body
    |> Poison.decode!
  end
end
