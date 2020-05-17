defmodule WikiRest.Citation do
  # TODO: Not all formats are JSON-encoded, so get_body must vary behavior.
  @spec citation(String.t(), String.t(), String.t()) :: map()
  def citation(project, format, query) do
    "https://#{project}/api/rest_v1/data/citation/#{format}/"
      <> URI.encode(query, &URI.char_unreserved?/1)
    |> WikiRest.Util.get_body()
  end
end
