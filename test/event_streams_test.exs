defmodule EventStreamsTest do
  use ExUnit.Case

  import Mox

  alias Wiki.EventStreams
  alias Wiki.Tests.HTTPoisonMock

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "follows events" do
    HTTPoisonMock
    |> expect(:get!, fn url, headers, options ->
      assert url == "https://stream.wikimedia.org/v2/stream/revision-create,revision-score"
      [{"user-agent", user_agent}] = headers
      assert String.match?(user_agent, ~r/wiki_elixir.*\d.*/)
      target = options[:stream_to]

      [
        ":ok\n\n",
        "event: message\n",
        "id: [{\"topic\":\"eqiad.mediawiki.page-create\",\"partition\":0,\"timestamp\":1590796085001},{\"topic\":\"codfw.mediawiki.page-create\",\"partition\":0,\"offset\":-1}]\n",
        "data: {\"$schema\":\"/mediawiki/revision/create/1.0.0\",\"meta\":{\"uri\":\"https://www.wikidata.org/wiki/Q95750653\",\"request_id\":\"19f5dd17-5263-4f8f-89a8-b91a669da9d8\",\"id\":\"73bcb733-f018-48a6-8fc0-d85dd8646549\",\"dt\":\"2020-05-29T23:48:05Z\",\"domain\":\"www.wikidata.org\",\"stream\":\"mediawiki.page-create\",\"topic\":\"eqiad.mediawiki.page-create\",\"partition\":0,\"offset\":162039062},\"database\":\"wikidatawiki\",\"page_id\":94619046,\"page_title\":\"Q95750653\",\"page_namespace\":0,\"rev_id\":1193879362,\"rev_timestamp\":\"2020-05-29T23:48:05Z\",\"rev_sha1\":\"8xhib3ygg6ceb3dmrtv43ii3pezq3o8\",\"rev_minor_edit\":false,\"rev_len\":1921,\"rev_content_model\":\"wikibase-item\",\"rev_content_format\":\"application/json\",\"performer\":{\"user_text\":\"MrProperLawAndOrder\",\"user_groups\":[\"*\",\"user\",\"autoconfirmed\"],\"user_is_bot\":false,\"user_id\":4181270,\"user_registration_dt\":\"2020-04-03T18:31:16Z\",\"user_edit_count\":531154},\"page_is_redirect\":false,\"comment\":\"/* wbeditentity-create-item:0| */ #quickstatements\",\"parsedcomment\":\"<span dir=\\\"auto\\\"><span class=\\\"autocomment\\\">wbeditentity-create-item:0|: </span> #quickstatements</span>\"}\n\n",
        "event: message\n",
        "id: [{\"topic\":\"eqiad.mediawiki.page-create\",\"partition\":0,\"timestamp\":1590796087001},{\"topic\":\"codfw.mediawiki.page-create\",\"partition\":0,\"offset\":-1}]\n",
        "data: {\"$schema\":\"/mediawiki/revision/create/1.0.0\",\"meta\":{\"uri\":\"https://ru.wikinews.org/wiki/%D0%9C%D0%B5%D0%BB%D0%B8%D0%BD%D0%B5\",\"request_id\":\"ce7b6a8e-b8c2-48a5-ae99-896966b7fa2b\",\"id\":\"4b538bef-6f49-4d50-bddf-2407aae58488\",\"dt\":\"2020-05-29T23:48:07Z\",\"domain\":\"ru.wikinews.org\",\"stream\":\"mediawiki.page-create\",\"topic\":\"eqiad.mediawiki.page-create\",\"partition\":0,\"offset\":162039065},\"database\":\"ruwikinews\",\"page_id\":2654475,\"page_title\":\"Мелине\",\"page_namespace\":0,\"rev_id\":3381702,\"rev_timestamp\":\"2020-05-29T23:48:07Z\",\"rev_sha1\":\"ppjenv2j3wld91yrznvsnbe5ybd9dtx\",\"rev_minor_edit\":false,\"rev_len\":45,\"rev_content_model\":\"wikitext\",\"rev_content_format\":\"text/x-wiki\",\"performer\":{\"user_text\":\"NewsBots\",\"user_groups\":[\"autoreview\",\"bot\",\"*\",\"user\",\"autoconfirmed\"],\"user_is_bot\":true,\"user_id\":19290,\"user_registration_dt\":\"2014-03-22T08:03:14Z\",\"user_edit_count\":2645631},\"page_is_redirect\":true,\"comment\":\"Автоматическое создание страницы.\",\"parsedcomment\":\"Автоматическое создание страницы.\"}\n\n"
      ]
      |> Enum.map(&send(target, %{chunk: &1}))
    end)

    EventStreams.start_link(streams: ~w(revision-create revision-score))

    result =
      EventStreams.stream()
      |> Stream.take(2)
      |> Enum.map(fn record -> record["comment"] end)

    assert result == [
             "/* wbeditentity-create-item:0| */ #quickstatements",
             "Автоматическое создание страницы."
           ]
  end
end
