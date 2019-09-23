defmodule Wikisource.SessionStore do
  @moduledoc """

  """
  use GenServer
  use Mnesiac.Store

  import Ecto.Query
  import Cluster.Strategy, only: [difference: 2]

  import Record, only: [defrecord: 3]
  @doc """
  Record definition for SessionStore session record.
  """
  defrecord(
    :session,
    __MODULE__,
    id: nil,
    data: nil,
    timestamp: nil
  )

  @typedoc """
  SessionStore session record field type definitions.
  """
  @type session ::
          record(
            :session,
            id: String.t(),
            data: Map.t(),
            timestamp: Integer.t()
          )

  @impl true
  def store_options,
    do: [
      record_name: __MODULE__,
      attributes: session() |> session() |> Keyword.keys(),
      index: [:timestamp],
      disc_copies: [node()]
    ]

  defp schedule_work(timeout) do
    Process.send_after(self(), :work, timeout)
  end

  def clean_sessions(table, max_age) do
    oldest_timestamp =
      (DateTime.utc_now() |> DateTime.to_unix) - max_age

    delete_old_sessions = fn ->
      old_sids =
        :mnesia.select(table, [
          {
            {table, :"$1", :_, :"$3"},
            [{:<, :"$3", oldest_timestamp}],
            [:"$1"]
          }
        ])

      for sid <- old_sids, do: :mnesia.delete({table, sid})

      from(s in Wikisource.Session, where: s.session_id in ^old_sids, update: [set: [delete_time: ^NaiveDateTime.utc_now()]])
      |> Wikisource.Repo.update_all([])
    end

    case :mnesia.transaction(delete_old_sessions) do
      {:atomic, _} -> :ok
      other -> other
    end
  end

  @impl true
  def handle_info(:work, {timeout, table, max_age} = state) do
    schedule_work(timeout)
    if Enum.member?(:mnesia.system_info(:local_tables), Wikisource.SessionStore) do
      :ok = clean_sessions(table, max_age)
    end
    {:noreply, state}
  end

  @impl true
  def init({timeout, _table, _max_age} = args) do
    schedule_work(timeout)
    {:ok, args}
  end

  def start_link(_args \\ nil) do
    with {:ok, table} <- Application.fetch_env(:wikisource, :table),
         {:ok, max_age} <- Application.fetch_env(:wikisource, :max_age) do
      timeout = Application.get_env(:wikisource, :check_interval, 60) * 1000
      GenServer.start_link(__MODULE__, {timeout, table, max_age})
    else
      :error -> {:error, :bad_configuration}
    end
  end

  def connect_node(node) do
    IO.puts("connect to node ")
    node |> IO.inspect
    :net_kernel.connect_node(node)
  end

  def nodes do
    # IO.inspect(Process.info(self(), :current_stacktrace), label: "STACKTRACE")
    connected_nodes = :erlang.nodes(:connected)
    cluster_nodes = case Mnesiac.cluster_status() |> Keyword.fetch(:running_nodes) do
      {:ok, cluster_nodes} -> cluster_nodes
      _ -> []
    end
    current_node = node()

    need_connect =
      connected_nodes
      |> difference(cluster_nodes)
      |> Enum.reject(fn n -> current_node == n end)

    for node <- need_connect do
      IO.puts("#{node} join cluster")
      Mnesiac.join_cluster(node)
    end

    connected_nodes
  end

  @impl true
  def resolve_conflict(cluster_node) do
    table_name = Keyword.get(store_options(), :record_name, __MODULE__)
    Logger.info(fn -> "[mnesiac:#{node()}] #{inspect(table_name)}: data found on both sides, use remote side #{cluster_node}." end)
    copy_store()
    :ok
  end
end
