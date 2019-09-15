defmodule WikisourceWeb.PageController do
  use WikisourceWeb, :controller
  use Wikisource, :elastic
  alias Phoenix.LiveView

  def search( params ) do
    { from, size, query } = case params do
      %{"query" => query, "from" => from, "size" => size } -> {from, size, query}
      %{"query" => query, "from" => from } -> {from, 10, query}
      %{"query" => query, "page" => page, "page_size" => size } -> { (page-1)*size , size, query}
      %{"query" => query, "page" => page } when is_integer(page) -> { (page-1)*10 , 10, query}
      %{"query" => query, "page" => page } when is_bitstring(page) -> { (String.to_integer(page)-1)*10 , 10, query}
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
            %{"match_phrase" => %{ "preface" => %{"query" => query, "analyzer" => "ik_zh_max", "slop" => 10} }},
            %{"match_phrase" => %{ "text" => %{"query" => query, "analyzer" => "ik_zh_max", "slop" => 20} }}
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
        {query, %Scrivener.Page{ entries:
          (Enum.map(hits, fn hit ->
            %{"name" => fetch_field(hit, "name"),
            "info" => fetch_field(hit, "info"),
            "preface" => fetch_field(hit, "preface"),
            "text" => fetch_field(hit, "text"),
            "url" => fetch_field(hit, "url")}
          end)),  page_number: round(from/size+1), page_size: size, total_entries: total, total_pages: round(total/size)}
        }
      _ ->
        {query, nil}
    end
  end

  def search(conn, params ) do
    { query, page } = search(params)
    render conn, "index.html", query: query, page: page
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

  def index_live(conn, _param) do
    LiveView.Controller.live_render(conn, WikisourceWeb.HomeView, session: %{})
  end

end
