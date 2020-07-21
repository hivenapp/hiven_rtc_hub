defmodule HivenRtcHub.Atlas.Locate do
  alias HivenRtcHub.Atlas.Region

  @spec get_best_server_for_region(String.t()) :: HivenRtcHub.Atlas.Server
  def get_best_server_for_region(region) do
    Region.get_servers(region)
    |> Enum.max_by(fn server -> server.active_rtc_sessions end)
  end
end
