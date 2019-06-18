defmodule WikiRest do
  @moduledoc """
  Access the [Wikimedia REST API](https://www.mediawiki.org/wiki/REST_API)

  ## TODO

  * Lots of ideosyncracies about how data is delayed in the backend.  Tune
  default time parameters to play nice with job update schedules.
  * Ideally, individual API methods would return an URL rather than perform the
  call, and would be transparently composed with an execute-and-unpack
  function.
  """

  @wikimedia_org "https://wikimedia.org/api/rest_v1"

  use WikiRest.Edits
  use WikiRest.Pageviews
  use WikiRest.Util
end
