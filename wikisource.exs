{:ok, body} = File.read("urls.txt")
urls = String.split(body, "\n") |> Enum.map(fn url -> String.replace(url, "<url>", "") |> String.replace("</url>", "") end)
IO.puts( List.first(urls) )

alias Wikisource.{Repo, Page}

defmodule SubArr do
  def sub_arr(arr, i) do
    case i do
      0 -> arr
      _ ->
        [_ | t] = arr
        sub_arr(t, i-1)
    end
  end
end

defmodule Consumer do
  use GenServer
  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def handle_call({:write, url}, _from, state) do
    try do
      case Repo.insert(%Page{ url: url, downloaded: 0 }) do
       {:ok, _} -> {:reply, {:ok, nil}, state}
       {_, err} -> {:reply, {:error, err}, state}
      end
     rescue
      e -> {:reply, {:error, e}, state}
     end
  end

  def handle_cast({:write, url}, state) do
    try do
      case Repo.insert(%Page{ url: url, downloaded: 0 }) do
       {:ok, _} -> {:noreply, state}
       {_, err} ->
        {:noreply, state}
      end
     rescue
      e ->
        {:noreply, state}
     end
  end

  def stop(server) do
    GenServer.stop(server)
  end
end

{:ok, consumer} = Consumer.start_link([])

# urls = SubArr.sub_arr(urls, 297622)
# urls = ["https://zh.wikisource.org/wiki/%E6%AC%BD%E5%AE%9A%E5%8F%A4%E4%BB%8A%E5%9C%96%E6%9B%B8%E9%9B%86%E6%88%90/%E5%8D%9A%E7%89%A9%E5%BD%99%E7%B7%A8/%E8%97%9D%E8%A1%93%E5%85%B8/%E7%AC%AC328%E5%8D%B7"]

total = Enum.reduce(urls, 0, fn url, total ->
  case GenServer.call(consumer, {:write, url}) do
    {:ok, _} -> total + 1
    {_, _} -> total
  end
end)

IO.puts(total)
