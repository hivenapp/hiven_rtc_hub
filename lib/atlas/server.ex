defmodule HivenRtcHub.Atlas.Server do
  @moduledoc """
  Definition and functions for Hiven RTC servers.
  Hiven RTC servers are physical or virtual servers that host
  the actual Hiven RTC code that sets up comms and siginaling.
  """

  defstruct [
    :name,
    :region
  ]
end
