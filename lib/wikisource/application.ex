defmodule Wikisource.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Wikisource.Repo, []),
      # Start the endpoint when the application starts
      supervisor(WikisourceWeb.Endpoint, []),
      supervisor(Wikisource.SessionStore, []),
      {Cluster.Supervisor, [Application.fetch_env!(:libcluster, :topologies), [name: Wikisource.ClusterSupervisor]]},
      # Start your own worker by calling: Wikisource.Worker.start_link(arg1, arg2, arg3)
      # worker(Wikisource.Worker, [arg1, arg2, arg3]),
      {
        Mnesiac.Supervisor,
        [
          Node.list(),
          [name: Wikisource.MnesiacSupervisor]
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wikisource.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WikisourceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
