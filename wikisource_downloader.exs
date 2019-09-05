import Ecto.Query
import HTTPoison
alias Wikisource.{Repo, Page}

HTTPoison.start

defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, {}}
  end

  def download(page) do
    try do
      post_download HTTPoison.get(page.url, [], [recv_timeout: 5000]), page
    rescue
      e -> {:error, 0}
    end
  end

  def post_download({:ok, %HTTPoison.Response{status_code: 200, body: body} }, page) do
    page = Ecto.Changeset.change page, html: body, downloaded: 1
    case Repo.update page do
      {:ok, _} ->
        {:ok, 0}
      {:error, e} ->
        {:error, e}
    end
  end

  def post_download({:error, e }, _) do
    {:error, e}
  end

  def handle_cast({:download, [from, page]}, state) do
    # IO.puts("will download " <> to_string(page.id))
      case download(page) do
        {:ok, _ } ->
          GenServer.cast(from, {:job_done, self()})
          # IO.puts(to_string(page.id) <> " downloaded")
          {:noreply, state}
        {_, err} ->
          # IO.puts(to_string(page.id) <> to_string(err))
          GenServer.cast(from, {:job_failed, self(), page})
          {:noreply, state}
      end
  end
end

defmodule WorkerSupervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Worker, name: Worker},
      {DynamicSupervisor, name: WorkerSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end

defmodule App do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def handle_call({:job}, _from, {workers, pages, count}) do
    _ = [0,1,2,3,4,5,6,7,8,9] |> Enum.reduce(pages, fn _, pages ->
      {:ok, pid} = Worker.start_link([])
      Process.monitor(pid)
      rest = case pages do
        [page | rest] ->
          GenServer.cast(pid, {:download, [self(), page]})
          rest
        _ -> []
      end

      Process.monitor(pid)
      rest
    end)
    {:reply, :ok, {workers, pages, count}}
  end

  def handle_call({:query}, _from, state) do
    {_, _, count} = state
    {:reply, count, state}
  end

  def init(_) do

    query = from(p in Page, where: p.downloaded == 0)
    pending = Repo.all(query)

    {:ok, {[], pending, 0}}
  end

  def handle_cast({:job_done, worker}, {workers, pages, count}) do
    rest = case pages do
      [page | rest] ->
        GenServer.cast(worker, {:download, [self(), page]})
        rest
      _ ->
        IO.puts("no more wikisource pages left")
        []
    end
    {:noreply, {workers, rest, count+1}}
  end

  def handle_cast({:job_failed, worker, page}, {workers, pages, count}) do
    # IO.puts("failed to download " <> to_string(page.id))
    pages = case pages do
      [page | rest] ->
        GenServer.cast(worker, {:download, [self(), page]})
        rest
      _ ->
        []
    end
    {:noreply, {workers, pages ++ [page] , count}}
  end

  def stop(server) do
    GenServer.stop(server)
  end

end


# import_file("wikisource_downloader.exs")
# {:ok, app} = App.start_link([])
# GenServer.call(app, {:job})
# GenServer.call(app, {:query})
