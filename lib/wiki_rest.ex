defmodule Wiki.Rest do
  @moduledoc """
  Access the [Wikimedia REST API](https://www.mediawiki.org/wiki/REST_API)

  ## TODO

  * Lots of idiosyncracies about how data is delayed in the backend.  Tune
  default time parameters to play nice with job update schedules.
  """

  # FIXME: from mix env @wikimedia_org Application.get_env(:wiki_elixir, :wikimedia_org)
  @wikimedia_org "https://wikimedia.org/api/rest_v1"

  # FIXME: how does this work, anyway
  def wikimedia_org() do
    @wikimedia_org
  end
end
