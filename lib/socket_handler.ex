defmodule HivenRtcHub.SocketHandler do
  @behaviour :cowboy_websocket

  @heartbeat_interval 5000
  @max_heartbeat_failures 3

  def init(request, _state) do
    state = %{server_name: nil, region: nil, last_hbt: nil,
    encoding: :json}

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    {:reply, construct_socket_msg(state.encoding, %{op: 1, d: %{hbt_int: @heartbeat_interval}}), state}
  end

  def websocket_handle({:text, json}, state) do
    with {:ok, json} <- Poison.decode(json) do
      case json["op"] do
        2 ->
          %{"server_name" => server_name, "region" => region} = json["d"]

          :ets.insert(:servers, {server_name, %{region: region, pid: self()}})
          :ets.insert(:servers_by_region, {region, server_name})

          Process.send_after(self(), {:heartbeat_check}, @heartbeat_interval)

          {:reply, construct_socket_msg(state.encoding, %{op: 3}), %{state | server_name: server_name, region: region}}
        4 ->
          %{"active_rtc_sessions" => active_rtc_sessions} = json["d"]

          [{_key, old_server_state}] = :ets.lookup(:servers, state.server_name)
          :ets.insert(:servers, {state.server_name, %{old_server_state | active_rtc_sessions: active_rtc_sessions}})

          {:ok, %{state | last_hbt: :os.system_time(:millisecond)}}
        _ -> {:stop, state}
      end
    end
  end

  def websocket_info({:heartbeat_check}, state) do
    {:ok, state}
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
