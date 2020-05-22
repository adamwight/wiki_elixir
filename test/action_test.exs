defmodule ActionTest do
  use ExUnit.Case, async: true

  import Mox

  alias Tesla.Env
  alias Wiki.Action
  alias Wiki.Action.Session
  alias Wiki.Tests.TeslaAdapterMock

  setup :verify_on_exit!

  test "returns new session" do
    session = Action.new("https://dewiki.test/w/api.php")
    %{__client__: client} = session
    assert length(client.pre) >= 1
  end

  test "gets successfully" do
    canned_response = %{
      "batchcomplete" => "",
      "query" => %{
        "statistics" => %{
          "activeusers" => 20_132,
          "admins" => 193,
          "articles" => 2_435_513,
          "edits" => 198_804_009,
          "images" => 129_180,
          "jobs" => 0,
          "pages" => 6_806_338,
          "queued-massmessages" => 0,
          "users" => 3_469_437
        }
      },
      "appended" => ["b"]
    }

    # FIXME: Why isn't JSON middleware decoding during testing?
    # |> Jason.encode!()

    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      {:ok, %Env{env | body: canned_response, headers: [], status: 200}}
    end)

    session = Action.new("https://dewiki.test/w/api.php")

    session = %Session{
      session
      | result: %{
          "appended" => ["a"],
          "isolated" => "foo",
          "query" => %{
            "statistics" => %{
              "merged" => true
            }
          }
        }
    }

    session =
      session
      |> Action.get(%{
        action: :query,
        format: :json,
        meta: :siteinfo,
        siprop: :statistics
      })

    assert session.result["appended"] == ["a", "b"]
    assert session.result["isolated"] == "foo"
    assert session.result["query"]["statistics"]["activeusers"] == 20_132
    assert session.result["query"]["statistics"]["merged"] == true
  end
end
