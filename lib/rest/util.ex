defmodule WikiRest.Util do
  defmacro __using__(_) do
    quote do
      defp normalize_title(title) do
        title |> String.replace(" ", "_")
      end

      defp get_body(url) do
        url
        |> HTTPoison.get!
        |> extract_body
      end

      defp extract_body(response) do
        response.body
        |> Poison.decode!
      end

      defp default_start_day() do
        Timex.today
        |> Timex.shift(days: -7)
        |> daystamp
      end

      defp today() do
        Timex.today |> daystamp
      end

      defp daystamp(datetime) do
        datetime |> Timex.format!("{YYYY}{0M}{0D}")
      end
    end
  end
end
