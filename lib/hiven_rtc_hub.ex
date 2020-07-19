defmodule HivenRtcHub do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ets.new(:servers, [:named_table, :public, :set])
    :ets.new(:servers_by_region, [:named_table, :public, :bag])

    # topologies = [
    #   example: [
    #     strategy: Cluster.Strategy.Epmd,
    #     config: [hosts: [:"hivencore1@Phineas-MacBook-Pro"]],
    #   ],
    #   hiven_consul: [
    #     strategy: Cluster.Strategy.Consul,
    #     config: [
    #       base_url: "http://consul.nectar.hiven.io:8500",
    #       dc: "dc1",
    #       service_name: "realtime-elixir",
    #       node_basename: "swarm",
    #       list_using: [
    #         Cluster.Strategy.Consul.Catalog,
    #       ]
    #     ]
    #   ]
    # ]

    children = [
      # {GenRegistry, worker_module: HivenSwarm.Sessions.StatefulSession},
      # {Cluster.Supervisor, [topologies, [name: HivenSwarm.ClusterSupervisor]]},
      Plug.Cowboy.child_spec(scheme: :http, plug: HivenRtcHub.Router, options: [port: 4001, dispatch: dispatch(), protocol_options: [idle_timeout: :infinity]]),
    ]

    opts = [strategy: :one_for_one, name: HivenSwarm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
        [
          {"/socket", HivenRtcHub.SocketHandler, []},
          {:_, Plug.Cowboy.Handler, {HivenSwarm.Metric.PrometheusExporter, []}}
        ]
      }
    ]
  end
end
