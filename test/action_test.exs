defmodule ActionTest do
  use ExUnit.Case, async: true

  import Mox

  alias Tesla.Env
  alias Wiki.Action
  alias Wiki.Action.Session
  alias Wiki.Tests.TeslaAdapterMock

  @url "https://dewiki.test/w/api.php"

  setup :verify_on_exit!

  test "returns new session" do
    session = Action.new(@url)
    %{__client__: client} = session
    assert length(client.pre) >= 1
  end

  test "gets successfully" do
    canned_response =
      %{
        "batchcomplete" => "",
        "query" => %{
          "general" => %{
            "mainpage" => "Main Page"
          }
        }
      }
      |> Jason.encode!()

    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      [{"user-agent", user_agent}] = env.headers

      assert String.match?(user_agent, ~r/wiki_elixir.*\d.*/)
      assert env.method == :get

      assert env.query == [
               action: :query,
               format: :json,
               formatversion: 2,
               meta: :siteinfo,
               siprop: :general
             ]

      headers = [{"content-type", "application/json; charset=utf-8"}]

      {:ok, %Env{env | body: canned_response, headers: headers, status: 200}}
    end)

    session =
      Action.new(
        @url,
        accumulate: true
      )
      |> Action.get(
        action: :query,
        meta: :siteinfo,
        siprop: :general
      )

    assert session.result["query"]["general"]["mainpage"] == "Main Page"
  end

  test "merges previous results" do
    canned_response = %{
      "batchcomplete" => "",
      "query" => %{
        "general" => %{
          "mainpage" => "Main Page"
        },
        "statistics" => %{
          "activeusers" => 20_132
        }
      },
      "appended" => ["b"]
    }

    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      [{"user-agent", user_agent}] = env.headers

      assert String.match?(user_agent, ~r/wiki_elixir.*\d.*/)
      assert env.method == :get

      assert env.query == [
               action: :query,
               format: :json,
               formatversion: 2,
               meta: :siteinfo,
               siprop: "general|statistics"
             ]

      {:ok, %Env{env | body: canned_response, headers: [], status: 200}}
    end)

    session =
      Action.new(
        @url,
        accumulate: true
      )

    session = %Session{
      session
      | state: [
          accumulated_result: %{
            "appended" => ["a"],
            "isolated" => "foo",
            "query" => %{
              "general" => %{
                "mainpage" => "Main Page"
              },
              "statistics" => %{
                "merged" => true
              }
            }
          }
        ]
    }

    session =
      session
      |> Action.get(
        action: :query,
        meta: :siteinfo,
        siprop: [:general, :statistics]
      )

    assert session.result["appended"] == ["a", "b"]
    assert session.result["isolated"] == "foo"
    assert session.result["query"]["statistics"]["activeusers"] == 20_132
    assert session.result["query"]["statistics"]["merged"] == true
  end

  test "doesn't collide literal pipes with separator" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      assert env.query[:multivalue] == "\x1fFoo|Bar\x1fBaz"
      {:ok, %Env{env | status: 200, body: %{a: 'b'}}}
    end)

    Action.new(@url)
    |> Action.get(multivalue: ["Foo|Bar", "Baz"])
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
               "action=login&format=json&formatversion=2&lgname=TestUser%40bot&lgpassword=botpass&lgtoken=5c31497c51b4b28f2d6c19f3349070d25eccae52%2B%5C"

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

    session = Action.new(@url)

    session =
      %Session{
        session
        | state: [
            cookies: %{"a" => "b"}
          ]
      }
      |> Wiki.Action.authenticate(
        "TestUser@bot",
        "botpass"
      )

    assert session.state[:cookies] == %{"mediawiki_session" => "new_cookie", "a" => "b"}
  end

  test "streams continuations" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      {:ok,
       %Env{
         env
         | body: %{
             "batchcomplete" => "",
             "continue" => %{"continue" => "-||", "rccontinue" => "20200519061025|633"},
             "query" => %{
               "recentchanges" => [
                 %{"revid" => 616},
                 %{"revid" => 615}
               ]
             }
           },
           status: 200
       }}
    end)
    |> expect(:call, fn env, _opts ->
      assert env.query == [
               {:action, :query},
               {:format, :json},
               {:formatversion, 2},
               {:list, :recentchanges},
               {:rclimit, 2},
               {"continue", "-||"},
               {"rccontinue", "20200519061025|633"}
             ]

      {:ok,
       %Env{
         env
         | body: %{
             "batchcomplete" => "",
             "query" => %{
               "recentchanges" => [
                 %{"revid" => 614},
                 %{"revid" => 613}
               ]
             }
           },
           status: 200
       }}
    end)

    recent_changes =
      Action.new(@url)
      |> Action.stream(
        action: :query,
        list: :recentchanges,
        rclimit: 2
      )
      |> Enum.flat_map(fn response -> response["query"]["recentchanges"] end)
      |> Enum.map(fn rc -> rc["revid"] end)

    assert recent_changes == [616, 615, 614, 613]
  end

  test "handles 404 response" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      {:ok,
       %Env{env | status: 404, body: "<html><head><title>404 Not Found</title></head></html>"}}
    end)

    error =
      assert_raise RuntimeError, fn ->
        Action.new(@url) |> Action.get(foo: :bar)
      end

    assert String.match?(error.message, ~r/404/)
  end

  test "handles network errors" do
    TeslaAdapterMock
    |> expect(:call, fn _env, _opts ->
      {:error, :nxdomain}
    end)

    error =
      assert_raise Tesla.Error, fn ->
        Action.new(@url)
        |> Action.get(foo: :bar)
      end

    assert error.reason == :nxdomain
  end

  test "handles empty response" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      {:ok, %Env{env | status: 200, body: ""}}
    end)

    error =
      assert_raise RuntimeError, fn ->
        Action.new(@url) |> Action.get(foo: :bar)
      end

    assert error.message == "Empty response"
  end

  test "handles API error in legacy format" do
    %{
      "error" => %{
        "info" => "Returned error"
      }
    }
    |> failed_body_case("Returned error")
  end

  test "handles API error with text" do
    %{
      "errors" => [
        %{"text" => "Returned error"}
      ]
    }
    |> failed_body_case("Returned error")
  end

  test "handles API error with html" do
    %{
      "errors" => [
        %{"html" => "<i>Returned error</i>"}
      ]
    }
    |> failed_body_case("<i>Returned error</i>")
  end

  test "handles API error with message spec" do
    %{
      "errors" => [
        %{"key" => "err-msg", "params" => [1, 2]}
      ]
    }
    |> failed_body_case("err-msg-1-2")
  end

  test "handles API error with code" do
    %{
      "errors" => [
        %{"code" => "err-code"}
      ]
    }
    |> failed_body_case("err-code")
  end

  defp failed_body_case(body, message) do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      {:ok, %Env{env | status: 200, body: body}}
    end)

    error =
      assert_raise RuntimeError, fn ->
        Action.new(@url) |> Action.get(foo: :bar)
      end

    assert error.message == message
  end
end
