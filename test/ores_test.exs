defmodule OresTest do
  use ExUnit.Case, async: true

  import Mox

  alias Tesla.Env
  alias Wiki.Ores
  alias Wiki.Tests.TeslaAdapterMock

  setup :verify_on_exit!

  test "requests singular resource" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      [{"user-agent", user_agent}] = env.headers

      assert String.match?(user_agent, ~r/wiki_elixir.*\d.*/)

      assert env.query == [models: "damaging", revids: 12_345]
      assert env.url == "https://ores.test/v3/scores/testwiki/"

      response = %{
        "testwiki" => %{
          "models" => %{
            "damaging" => %{"version" => "0.5.0"}
          },
          "scores" => %{
            "12345" => %{
              "damaging" => %{
                "score" => %{
                  "prediction" => false,
                  "probability" => %{
                    "false" => 0.9785756543468973,
                    "true" => 0.021424345653102705
                  }
                }
              }
            }
          }
        }
      }

      {:ok, %Env{env | body: response, status: 200}}
    end)

    session =
      Ores.new("testwiki")
      |> Ores.request(%{
        models: "damaging",
        revids: 12_345
      })

    assert session["testwiki"]["scores"]["12345"]["damaging"]["score"]["prediction"] == false
  end

  test "requests plural resource" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      assert env.query == [models: "damaging|wp10", revids: "12345|67890"]

      response = %{
        "testwiki" => %{
          "models" => %{
            "damaging" => %{"version" => "0.5.0"},
            "wp10" => %{"version" => "0.8.2"}
          },
          "scores" => %{
            "12345" => %{
              "damaging" => %{
                "score" => %{
                  "prediction" => true,
                  "probability" => %{
                    "false" => 0.021424345653102705,
                    "true" => 0.9785756543468973
                  }
                }
              },
              "wp10" => %{
                "score" => %{
                  "prediction" => "Start",
                  "probability" => %{
                    "B" => 0.16105940831285498,
                    "C" => 0.14372727363404417,
                    "FA" => 0.00502943217056253,
                    "GA" => 0.010107802964660814,
                    "Start" => 0.6191023389444846,
                    "Stub" => 0.06097374397339299
                  }
                }
              }
            },
            "67890" => %{
              "damaging" => %{
                "score" => %{
                  "prediction" => false,
                  "probability" => %{
                    "false" => 0.9785756543468973,
                    "true" => 0.021424345653102705
                  }
                }
              },
              "wp10" => %{
                "score" => %{
                  "prediction" => "Start",
                  "probability" => %{
                    "B" => 0.16105940831285498,
                    "C" => 0.14372727363404417,
                    "FA" => 0.00502943217056253,
                    "GA" => 0.010107802964660814,
                    "Start" => 0.6191023389444846,
                    "Stub" => 0.06097374397339299
                  }
                }
              }
            }
          }
        }
      }

      {:ok, %Env{env | body: response, status: 200}}
    end)

    session =
      Ores.new("testwiki")
      |> Ores.request(%{
        models: ~w(damaging wp10),
        revids: [12_345, 67_890]
      })

    assert session["testwiki"]["scores"]["67890"]["wp10"]["score"]["prediction"] == "Start"
  end

  test "handles network error" do
    TeslaAdapterMock
    |> expect(:call, fn _env, _opts ->
      {:error, :nxdomain}
    end)

    error =
      assert_raise Tesla.Error, fn ->
        Ores.new("testwiki")
        |> Ores.request(%{})
      end

    assert error.reason == :nxdomain
  end

  test "handles empty success" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      {:ok, %Env{env | status: 200, body: ""}}
    end)

    error =
      assert_raise RuntimeError, fn ->
        Ores.new("testwiki")
        |> Ores.request(%{})
      end

    assert error.message == "Empty response"
  end

  test "handles malformed JSON" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      body = "<html><head><title>Not found!</title></head></html>"
      {:ok, %Env{env | status: 404, body: body}}
    end)

    error =
      assert_raise RuntimeError, fn ->
        Ores.new("testwiki")
        |> Ores.request(%{})
      end

    assert error.message == "Malformed response, HTTP status 404"
  end

  test "handles server error" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      {:ok, %Env{env | status: 500, body: %{"foo" => "bar"}}}
    end)

    error =
      assert_raise RuntimeError, fn ->
        Ores.new("testwiki")
        |> Ores.request(%{})
      end

    assert error.message == "Error received with HTTP status 500"
  end

  test "handles API error with 404" do
    TeslaAdapterMock
    |> expect(:call, fn env, _opts ->
      body = %{
        "error" => %{
          "code" => "not found",
          "message" => "No scorers available for zenwiki"
        }
      }

      {:ok, %Env{env | status: 404, body: body}}
    end)

    error =
      assert_raise RuntimeError, fn ->
        Ores.new("zenwiki")
        |> Ores.request(%{})
      end

    assert error.message == "No scorers available for zenwiki"
  end
end
