defmodule WikisourceWeb.DataSource do
  import Ecto.Query

  alias Wikisource.Repo

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, params) do
    case params do
      %{chapters: true, offset: offset, first: first} ->
        last = offset + first
        query = from r in queryable, select: r, select_merge: %{chapter_number: fragment("row_number() over (PARTITION by parent_id order by \"name\")")}
        from r in subquery(query), select: %Wikisource.Book{id: r.id, name: r.name, info: r.info, preface: r.preface, info_html: r.info_html, preface_html: r.preface_html}, where: r.chapter_number >= ^offset and r.chapter_number < ^last
      %{order_by: order_by, offset: from, first: size} -> from record in queryable, order_by: ^order_by, offset: ^from, limit: ^size
      %{offset: from, first: size} -> from record in queryable, offset: ^from, limit: ^size
      %{order_by: order_by, offset: from} -> from record in queryable, order_by: ^order_by, offset: ^from, limit: 10
      %{order_by: order_by} -> from record in queryable, order_by: ^order_by, offset: 0, limit: 10
      %{} -> queryable
    end
  end
end
