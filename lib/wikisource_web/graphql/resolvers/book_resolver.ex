defmodule WikisourceWeb.Resolvers.BookResolver do
  import Ecto.Query
  alias Wikisource.{Book, Repo}

  def get(_parent, args, _resolutions) do
    case Repo.get(Book, args[:id]) do
      nil -> {:error, "Not found"}
      book -> {:ok, book}
    end
  end

  def chapters(parent, args, _resolutions) do

    from = Map.get(args, :offset, 0)
    size = Map.get(args, :first, 10)
    parent_id = parent.id

    count_query = from b in Book, select: b, where: b.parent_id == ^parent_id
    # total = Repo.aggregate(count_query, :count, :id)
    books = Repo.all(from b in Book, select: b, order_by: :name, offset: ^from, limit: ^size, where: b.parent_id == ^parent_id)
    # {:ok, %{query: "", from: from, size: size, total: total, books: books }}
    {:ok, books}
  end

  def list(_parent, args, _resolutions) do

    parent = Map.get(args, :parent, 0)
    from = Map.get(args, :offset, 0)
    size = Map.get(args, :first, 10)

    {total, books} = if parent <= 0 do
      {Repo.aggregate(Book, :count, :id), Repo.all(from b in Book, select: b, where: is_nil(b.parent_id), offset: ^from, limit: ^size)}
    else
      {Repo.aggregate(from(b in Book, [select: b, where: b.parent_id == ^parent]), :count, :id), Repo.all(from b in Book, select: b, where: b.parent_id == ^parent, offset: ^from, limit: ^size, order_by: :name)}
    end
    {:ok, %{query: "", from: from, size: size, total: total, books: books }}
  end

  def search(_parent, args, _resolutions) do
    query = Map.get(args, :query, "")
    from = Map.get(args, :offset, 0)
    size = Map.get(args, :first, 10)

    case Elastix.Search.search(elastic_url(), "wikisource", [""], %{
      "from" => from,
      "size" => size,
      "query" => %{
                "multi_match" => %{
                    "query" =>    query,
                    "fields" => [ "name", "info", "preface", "text" ],
                    "operator" => "and"
                  }
            },
            "highlight" => %{
                "fields" => %{
                    "name" => %{},
                    "info" => %{},
                    "preface" => %{},
                    "text" => %{},
                }
            }
    }) do
      {:ok, %HTTPoison.Response{ body: %{ "hits" => %{ "hits" => hits , "total" => %{"value" => total }}} }} ->
        urls = hits |> Enum.map(fn hit -> hit |> Map.get("_source") |> Map.get("url", "") end)
        books = Repo.all(from b in Book, where: b.url in ^urls, select: b)
        books = urls |> Enum.map(fn url ->
          Enum.find(books, fn book ->
            book.url == url
          end)
        end)
        {:ok, %{query: query, from: from, size: size, total: total, books: books }}
      _ -> {:ok, %{query: query, from: from, size: size, total: 0, books: []}}
    end

  end

  def filter(_parent, args, _resolutions) do
    name = Map.get(args, :name, "")
    info = Map.get(args, :info, "")
    preface = Map.get(args, :preface, "")
    text = Map.get(args, :text, "")

    from = Map.get(args, :offset, 0)
    size = Map.get(args, :first, 10)

    should_arr = [{"name", name}, {"info", info}, {"preface", preface}, {"text", text}] |> Enum.reduce([],
    fn it, acc ->
      case it do
        {_, ""} -> acc
        {field, query} -> [%{"match_phrase" => %{ field => %{ "query" =>  query, "analyzer" => "ik_zh_max"} } }] ++ acc
      end
    end)

    case Elastix.Search.search(elastic_url(), "wikisource", [""], %{
      "from" => from,
      "size" => size,
      "query" => %{
          "bool" => %{"must" => should_arr}
      },
      "highlight" => %{
          "fields" => %{
              "name" => %{},
              "info" => %{},
              "preface" => %{},
              "text" => %{},
          }
      }
    }) do
      {:ok, %HTTPoison.Response{ body: %{ "hits" => %{ "hits" => hits , "total" => %{"value" => total }}} }} ->
        urls = hits |> Enum.map(fn hit -> hit |> Map.get("_source") |> Map.get("url", "") end)
        books = Repo.all(from b in Book, where: b.url in ^urls, select: b)
        books = urls |> Enum.map(fn url ->
          Enum.find(books, fn book ->
            book.url == url
          end)
        end)
        {:ok, %{query: "", from: from, size: size, total: total, books: books }}
      _ -> {:ok, %{query: "", from: from, size: size, total: 0, books: []}}
    end

  end

  def elastic_url do
    Application.get_env(:elastix, "url", "http://localhost:9200")
  end
end
