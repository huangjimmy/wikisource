defmodule WikisourceWeb.PageController do
  use WikisourceWeb, :controller

  def search(conn, params ) do
    { from, size, query } = case params do
      %{"query" => query, "from" => from, "size" => size } -> {from, size, query}
      %{"query" => query, "from" => from } -> {from, 10, query}
      %{"query" => query, "page" => page, "page_size" => size } -> { (page-1)*size , size, query}
      %{"query" => query, "page" => page } -> { (String.to_integer(page)-1)*10 , 10, query}
      %{"query" => query } -> {0, 10, query}
      _ -> {0, 10, ""}
    end

    case Elastix.Search.search(elastic_url(), "wikisource", [""], %{
      "from" => from,
      "size" => size,
      "query" => %{
        "bool" => %{
          "should" => [
            %{"match_phrase" => %{ "name" => %{"query" => query, "analyzer" => "ik_zh_max"}}},
            %{"match_phrase" => %{ "info" => %{"query" => query, "analyzer" => "ik_zh_max"} }},
            %{"match_phrase" => %{ "preface" => %{"query" => query, "analyzer" => "ik_zh_max"} }},
            %{"match_phrase" => %{ "text" => %{"query" => query, "analyzer" => "ik_zh_max"} }}
          ]
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
        render conn, "index.html", query: query, page: %Scrivener.Page{ entries:
          (Enum.map(hits, fn hit ->
            %{"name" => fetch_field(hit, "name"),
            "info" => fetch_field(hit, "info"),
            "preface" => fetch_field(hit, "preface"),
            "text" => fetch_field(hit, "text"),
            "url" => fetch_field(hit, "url")}
          end)),  page_number: round(from/size+1), page_size: size, total_entries: total, total_pages: round(total/size)}
      _ ->
        render conn, "index.html", query: query, page: nil
    end
  end

  def fetch_field(hit, field) do
    %{ "highlight" => hightlight, "_source" => source } = hit
     case Map.fetch(hightlight, field) do
       {:ok, val} -> val
       _ -> if field == "text" do
           ""
         else
           Map.fetch!(source, field)
         end
    end
  end

  def index(conn, _params) do
    render conn, "index.html", query: "", page: nil
  end

  def elastic_url do
    Application.get_env(:elastix, "url", "http://localhost:9200")
  end

end
