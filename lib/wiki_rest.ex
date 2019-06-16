defmodule WikiRest do
  @moduledoc """
  Access the [Wikimedia REST API](https://www.mediawiki.org/wiki/REST_API)
  """

  def http_get(url) do
    url
    |> HTTPotion.get!
    |> (&(&1.body)).()
  end

  def pageviews(project, article, start, finish) do
    IO.puts "https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/#{project}/all-access/all-agents/#{article}/daily/#{start}/#{finish}"
  end
end
