defmodule Wikisource.SearchQuery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "search_query" do
    field(:query, :string)
    field(:_utf8, :string)
    field(:page, :integer)
  end

  @doc false
  def changeset(query, attrs) do
    query
    |> cast(attrs, [:query, :_utf8, :page])
  end
end

defmodule WikisourceWeb.HomeView do
  use Phoenix.LiveView

  import Phoenix.LiveView

  def render(assigns) do
    WikisourceWeb.PageView.render("home.html", assigns)
  end

  def mount(_session, socket) do
    query = %Wikisource.SearchQuery{}

    {:ok,
     assign(socket,
       changeset: Wikisource.SearchQuery.changeset(query, %{query: ""}),
       page_content: nil,
       page: 1,
       query: "",
       loading: false
     )}
  end

  def handle_event("search", value, socket) do
    query = %Wikisource.SearchQuery{}
    %{assigns: %{page: page, query: old_query_string}} = socket
    %{"search_query" => %{"query" => query_string}} = value

    page =
      if old_query_string == query_string do
        page
      else
        1
      end

    socket =
      assign(socket,
        query: query_string,
        page: page,
        changeset: Wikisource.SearchQuery.changeset(query, %{query: query_string})
      )

    socket =
      case query_string do
        "" ->
          assign(socket, loading: false, page_content: nil)

        _ ->
          send(self(), :search)
          assign(socket, loading: true)
      end

    {:noreply, socket}
  end

  def handle_event("page", value, socket) do
    query = %Wikisource.SearchQuery{}
    %{assigns: %{query: query_string}} = socket

    query_string = value |> Map.get("search_query", %{}) |> Map.get("query", query_string)

    %{"search_query" => %{"page" => page}} = value

    socket =
      assign(socket,
        page: page,
        query: query_string,
        changeset: Wikisource.SearchQuery.changeset(query, %{query: query_string})
      )

    socket =
      case query_string do
        "" ->
          assign(socket, loading: false, page_content: nil)

        _ ->
          send(self(), :search)
          assign(socket, loading: true)
      end

    {:noreply, socket}
  end

  def handle_event("validate", _value, socket) do
    {:noreply, socket}
  end

  def handle_params(params, _uri, socket) do
    %{assigns: %{page: _page, query: old_query_string}} = socket

    query = Map.get(params, "query", old_query_string)
    page = Map.get(params, "page", 1)

    case {query, page} do
      {"", _} ->
        {:noreply, socket}

      _ ->
        socket = assign(socket, loading: true)
        handle_event("page", %{"search_query" => %{"page" => page, "query" => query}}, socket)
    end
  end

  def handle_info(:search, socket) do
    %{assigns: %{query: query_string, page: page}} = socket

    {_, page_content} =
      WikisourceWeb.PageController.search(%{"query" => query_string, "page" => page})

    {:noreply, assign(socket, page_content: page_content, loading: false)}
  end
end
