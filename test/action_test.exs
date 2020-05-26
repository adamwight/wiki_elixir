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
      [{"user-agent", user_agent}] = env.headers
      assert String.match?(user_agent, ~r/wiki_elixir/)
      assert env.method == :get
      assert env.query == [action: :query, format: :json, meta: :siteinfo, siprop: :statistics]

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

  test "posts using body, authenticates using cookie jar" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      assert env.method == :get

      {:ok,
       %Env{
         env
         | body: %{
             "batchcomplete" => "",
             "query" => %{
               "tokens" => %{"logintoken" => "5c31497c51b4b28f2d6c19f3349070d25eccae52+\\"}
             }
           },
           headers: [
             {"set-cookie",
              "mediawiki_session=aam5aqq00euke0tn99fin92j4nnbueav; path=/; HttpOnly"}
           ],
           status: 200
       }}
    end)
    |> expect(:call, fn env, _opts ->
      assert env.method == :post
      assert env.query == []

      assert env.body ==
               "action=login&format=json&lgname=TestUser%40bot&lgpassword=botpass&lgtoken=5c31497c51b4b28f2d6c19f3349070d25eccae52%2B%5C"

      assert List.keyfind(env.headers, "cookie", 0) ==
               {"cookie", "a=b; mediawiki_session=aam5aqq00euke0tn99fin92j4nnbueav"}

      {:ok,
       %Env{
         env
         | body: %{
             "login" => %{"result" => "Success", "lguserid" => 1, "lgusername" => "TestUser"}
           },
           headers:
             List.keystore(
               env.headers,
               "set-cookie",
               0,
               {"set-cookie", "mediawiki_session=new_cookie; path=/; HttpOnly"}
             ),
           status: 200
       }}
    end)

    session = Action.new("https://dewiki.test/w/api.php")

    session =
      %{session | __cookies__: %{"a" => "b"}}
      |> Wiki.Action.authenticate(
        "TestUser@bot",
        "botpass"
      )

    assert session.__cookies__ == %{"mediawiki_session" => "new_cookie", "a" => "b"}
  end
end
