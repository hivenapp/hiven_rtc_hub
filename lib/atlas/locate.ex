defmodule HivenRtcHub.Atlas.Locate do
  alias HivenRtcHub.Atlas.Region

  @doc """
  Returns a server ETS map for the server with the least active RTC sessions

  ## Parameters

    - region: Region string

  ## Examples

    HivenRtcHub.Atlas.Locate.get_best_server_for_region("us-west")
    %{active_rtc_sessions: 29, pid: #PID<3.357.0>, region: "eu-west"}

  """
  @spec get_best_server_for_region(String.t()) :: HivenRtcHub.Atlas.Server
  def get_best_server_for_region(region) do
    Region.get_servers(region)
    |> Enum.max_by(fn server -> server.active_rtc_sessions end)
  end
end
