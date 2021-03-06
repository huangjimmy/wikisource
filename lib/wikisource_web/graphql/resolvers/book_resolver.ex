defmodule WikisourceWeb.Resolvers.BookResolver do
  import Ecto.Query
  import WikisourceWeb.PageController, only: [fetch_field: 2]
  alias Wikisource.{Book, Repo}

  use Wikisource, :elastic

  @invalid_session_error %{message: "unauthorized", error_code: 401}

  def get(_parent, args, %{context: %{session_id: _}} = _resolutions) do
    case Repo.get(Book, args[:id]) do
      nil -> {:error, "Not found"}
      book -> {:ok, book}
    end
  end

  def get(_parent, _args, _resolutions) do
    {:error, @invalid_session_error}
  end

  def chapters(parent, args, %{context: %{session_id: _}} = _resolutions) do
    from = Map.get(args, :offset, 0)
    size = Map.get(args, :first, 10)
    parent_id = parent.id

    # count_query = from b in Book, select: b, where: b.parent_id == ^parent_id
    # total = Repo.aggregate(count_query, :count, :id)
    books = Repo.all(from b in Book, select: b, order_by: :name, offset: ^from, limit: ^size, where: b.parent_id == ^parent_id)
    # {:ok, %{query: "", from: from, size: size, total: total, books: books }}
    {:ok, books}
  end

  def chapters(_parent, _args, _resolutions) do
    {:error, @invalid_session_error}
  end

  def list(_parent, args, %{context: %{session_id: _}} =_resolutions) do

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

  def list(_parent, _args, _resolutions) do
    {:error, @invalid_session_error}
  end

  def search(_parent, args, %{context: %{session_id: _}} = _resolutions) do
    query = Map.get(args, :query, "")
    from = Map.get(args, :offset, 0)
    size = Map.get(args, :first, 10)
    size = if size > 20, do: 20, else: size

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

        book_table = :ets.new(:book_table, [:set, :protected, :named_table])

        urls = hits |> Enum.map(fn hit ->
          url = hit |> Map.get("_source") |> Map.get("url", "")
          :ets.insert(book_table, {url, hit})
          url
        end)

        books = Repo.all(from b in Book, where: b.url in ^urls, select: b)
        books = urls |> Enum.map(fn url ->
          book = Enum.find(books, fn book ->
            book.url == url
          end)

          [{_url, hit} | _ ] = :ets.lookup(book_table, url)
          book = Map.put(book, :text_highlight, fetch_field(hit, "text"))
          book = Map.put(book, :name_highlight, fetch_field(hit, "name"))
          book = Map.put(book, :info_highlight, fetch_field(hit, "info"))
          book = Map.put(book, :preface_highlight, fetch_field(hit, "preface"))

          book
        end)

        :ets.delete(book_table)

        {:ok, %{query: query, offset: from, first: size, total: total, books: books }}
      _ -> {:ok, %{query: query, offset: from, first: size, total: 0, books: []}}
    end

  end

  def search(_parent, _args, _resolutions) do
    {:error, @invalid_session_error}
  end

  def filter(_parent, args, %{context: %{session_id: _}} = _resolutions) do
    name = Map.get(args, :name, "")
    info = Map.get(args, :info, "")
    preface = Map.get(args, :preface, "")
    text = Map.get(args, :text, "")

    from = Map.get(args, :offset, 0)
    size = Map.get(args, :first, 10)
    size = if size > 20, do: 20, else: size

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

        book_table = :ets.new(:book_table, [:set, :protected, :named_table])

        urls = hits |> Enum.map(fn hit ->
          url = hit |> Map.get("_source") |> Map.get("url", "")
          :ets.insert(book_table, {url, hit})
          url
        end)
        books = Repo.all(from b in Book, where: b.url in ^urls, select: b)
        books = urls |> Enum.map(fn url ->
          book = Enum.find(books, fn book ->
            book.url == url
          end)

          [{_url, hit} | _ ] = :ets.lookup(book_table, url)
          book = Map.put(book, :text_highlight, fetch_field(hit, "text"))
          book = Map.put(book, :name_highlight, fetch_field(hit, "name"))
          book = Map.put(book, :info_highlight, fetch_field(hit, "info"))
          book = Map.put(book, :preface_highlight, fetch_field(hit, "preface"))

          book
        end)

        :ets.delete(book_table)

        {:ok, %{query: "", offset: from, first: size, total: total, books: books }}
      _ -> {:ok, %{query: "", offset: from, first: size, total: 0, books: []}}
    end

  end

  def filter(_parent, _args, _resolutions) do
    {:error, @invalid_session_error}
  end

end
