defmodule HivenRtcHub.Atlas.Region do
  @moduledoc """
  Definition and functions for Hiven RTC regions.
  Hiven RTC regions are areas of the world which multiple RTC
  servers can reside. Remember, servers can be part of different
  providers so they are cloud agnostic
  """

  @regions %{
    "us-east" => %{
      id: "us-east",
      friendly_name: "US East"
    },
    "us-west" => %{
      id: "us-west",
      friendly_name: "US West"
    },
    "eu-west" => %{
      id: "eu-west",
      friendly_name: "Europe West"
    }
  }

  defstruct [
    :id,
    :friendly_name
  ]

  # defguard is_region(term)
  #   when is_string(term) and term in @regions

  @spec get(term) :: map()
  def get(id), do: @regions[id]

  def get_servers(region) do
    :ets.lookup(:servers_by_region, region)
    |> Enum.map(fn {_key, server_name} ->
      [{_key, server}] = :ets.lookup(:servers, server_name)

      server
    end)
  end
end
