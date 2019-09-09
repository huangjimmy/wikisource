defmodule WikisourceWeb.DataSource do
  import Ecto.Query

  alias Wikisource.Repo

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, params) do
    IO.inspect(queryable)
    IO.inspect(params)
    case params do
      %{order_by: order_by, from: from, size: size} -> from record in queryable, order_by: ^order_by, offset: ^from, limit: ^size
      %{from: from, size: size} -> from record in queryable, offset: ^from, limit: ^size
      %{order_by: order_by, from: from} -> from record in queryable, order_by: ^order_by, offset: ^from, limit: 10
      %{order_by: order_by} -> from record in queryable, order_by: ^order_by, offset: 0, limit: 10
      %{} -> queryable
    end
  end
end
