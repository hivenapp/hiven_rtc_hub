defmodule HivenRtcHub.SocketHandler do
  require Logger

  alias HivenRtcHub.Atlas.Region

  @behaviour :cowboy_websocket

  @heartbeat_interval 5000
  @max_heartbeat_failures 3
  @max_error_boundary_millis 200

  def init(request, _state) do
    state = %{server_name: nil, region: nil, last_hbt: nil, hbt_failures: 0, encoding: :json}

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    {:reply, construct_socket_msg(state.encoding, %{op: 1, d: %{hbt_int: @heartbeat_interval}}), state}
  end

  def websocket_handle({:text, json}, state) do
    with {:ok, json} <- Poison.decode(json) do
      handle_incoming_payload(json, state)
    end
  end

  def websocket_info({:heartbeat_check}, state) do
    success = :os.system_time(:millisecond) - state.last_hbt < @heartbeat_interval + @max_error_boundary_millis

    unless success do
      cond do
        state.hbt_failures + 1 == @max_heartbeat_failures ->
          # Too many failed heartbeats in a row
          # Let's assume the RTC server is dead and close this socket
          Logger.error("#{state.server_name} -> Reached max hbt failures... assuming dead")
          {:reply, {:close, 1008, "max_heartbeat_failures_reached"}, state}
        true ->
          Logger.warn("#{state.server_name} -> Failed to heartbeat (#{state.hbt_failures + 1} / #{@max_heartbeat_failures})")

          Process.send_after(self(), {:heartbeat_check}, @heartbeat_interval + @max_error_boundary_millis)

          {:ok, %{state | hbt_failures: state.hbt_failures + 1}}
      end
    else
      Process.send_after(self(), {:heartbeat_check}, @heartbeat_interval + @max_error_boundary_millis)

      {:ok, %{state | hbt_failures: 0}}
    end
  end

  def terminate(:ok, _req, state) do
    :ets.delete(:servers, state.server_name)
    :ets.delete_object(:servers_by_region, {state.region, state.server_name})

    {:ok, state}
  end

  # Init / Auth
  defp handle_incoming_payload(%{"op" => 2, "d" => data}, state) do
    %{"server_name" => server_name, "region" => region} = data

    case Region.get(region) do
      nil ->
        {:reply, {:close, 4004, "invalid_region"}, state}
      _ ->
        :ets.insert(:servers, {server_name, %{region: region, pid: self(), active_rtc_sessions: 0}})
        :ets.insert(:servers_by_region, {region, server_name})

        Logger.info("#{server_name}:#{region} -> Joined RTC Hub")

        Process.send_after(self(), {:heartbeat_check}, @heartbeat_interval + @max_error_boundary_millis)

        {:reply, construct_socket_msg(state.encoding, %{op: 3}), %{state | server_name: server_name, region: region, last_hbt: :os.system_time(:millisecond)}}
    end
  end

  # Heartbeat
  defp handle_incoming_payload(%{"op" => 4, "d" => data}, state) do
    %{"active_rtc_sessions" => active_rtc_sessions} = data

    [{_key, old_server_state}] = :ets.lookup(:servers, state.server_name)
    :ets.insert(:servers, {state.server_name, %{old_server_state | active_rtc_sessions: active_rtc_sessions}})

    {:ok, %{state | last_hbt: :os.system_time(:millisecond)}}
  end

  defp construct_socket_msg(compression, data) do
    case compression do
      :zlib ->
        data = data |> Poison.encode!

        z = :zlib.open()
        :zlib.deflateInit(z)

        data = :zlib.deflate(z, data, :finish)

        :zlib.deflateEnd(z)

        {:binary, data}
      _ ->
        data = data
        |> Poison.encode!

        {:text, data}
    end
  end

end
