defmodule Wiki.Rest.Citation do
  @moduledoc """
  Transform a web URL into a citation format using the [Citoid](https://www.mediawiki.org/wiki/Citoid)
  service, https://en.wikipedia.org/api/rest_v1/#/Citation
  """

  alias Wiki.Rest.Util

  # TODO: Not all formats are JSON-encoded, so get_body must vary behavior.
  @spec citation(String.t(), String.t(), String.t()) :: map()
  def citation(project, format, query) do
    ("https://#{project}/api/rest_v1/data/citation/#{format}/" <>
       URI.encode(query, &URI.char_unreserved?/1))
    |> Util.get_body()
  end
end
