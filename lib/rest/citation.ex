defmodule WikiRest.Citation do
  defmacro __using__(_) do
    quote do
      # TODO: Not all formats are JSON-encoded, so get_body must vary behavior.
      def citation(project, format, query) do
        "https://#{project}/api/rest_v1/data/citation/#{format}/#{URI.encode(query, &URI.char_unreserved?/1)}"
        |> get_body
      end
    end
  end
end
