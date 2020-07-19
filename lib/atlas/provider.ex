defmodule HivenRtcHub.Atlas.Provider do
  @moduledoc """
  Definition and functions for Hiven RTC service providers.
  Hiven RTC providers are cloud or bare-metal server hosts
  which we use to host Hiven RTC servers.
  """

  @providers %{
    "gcloud" => %{
      id: "gcloud",
      friendly_name: "Google Cloud",
      regions_served: ["us-east", "us-west", "eu-west"],
      hiven_net: false
    }
  }

  defstruct [
    :id,
    :friendly_name,
    :regions_served,
    :hiven_net
  ]

  @spec get(term) :: map()
  def get(id), do: @providers[id]
end
