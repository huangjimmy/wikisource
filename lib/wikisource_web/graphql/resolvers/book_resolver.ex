defmodule WikisourceWeb.Resolvers.BookResolver do
  import Ecto.Query
  alias Wikisource.{Book, Repo}

  def get(_parent, args, _resolutions) do
    case Repo.get(Book, args[:id]) do
      nil -> {:error, "Not found"}
      book -> {:ok, book}
    end
  end

  def search(_parent, args, _resolutions) do
    query = Map.get(args, :query, "")
    from = Map.get(args, :from, 0)
    size = Map.get(args, :size, 10)

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

    from = Map.get(args, :from, 0)
    size = Map.get(args, :size, 10)

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
