defmodule WikiRest do
  @moduledoc """
  Access the [Wikimedia REST API](https://www.mediawiki.org/wiki/REST_API)

  ## TODO

  * Lots of ideosyncracies about how data is delayed in the backend.  Tune
  default time parameters to play nice with job update schedules.
  """

  @wikimedia_org Application.get_env(:wiki_elixir, :wikimedia_org)

  use WikiRest.Citation
  use WikiRest.Edits
  use WikiRest.Pageviews
  use WikiRest.Util
end
