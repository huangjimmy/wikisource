defmodule Wikisource.SearchQuery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "search_query" do
    field :query, :string
    field :_utf8, :string
    field :page, :integer
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
    {:ok, assign(socket, changeset: Wikisource.SearchQuery.changeset(query, %{query: ""}), page_content: nil, page: 1, query: "" )}
  end

  def handle_event("search", value, socket) do
    query = %Wikisource.SearchQuery{}
    %{ assigns: %{ page: page, query: old_query_string } } = socket
    %{"search_query" => %{ "query" => query_string } } = value


    page = if old_query_string == query_string do
      page
    else
      1
    end

    params = %{ "query" => query_string, "page" => page }

    {query_string, page_content} = case query_string do
      "" -> {query_string, nil}
      _ -> WikisourceWeb.PageController.search(params)
    end
    {:noreply, assign(socket, page_content: page_content, query: query_string, changeset: Wikisource.SearchQuery.changeset(query, %{query: query_string})) }
  end

  def handle_event("page", value, socket) do
    query = %Wikisource.SearchQuery{}
    %{ assigns: %{ query: query_string } } = socket
    %{"search_query" => %{ "page" => page } } = value
    params = %{ "query" => query_string, "page" => page }

    {query_string, page_content} = case query_string do
      "" -> {query_string, nil}
      _ -> WikisourceWeb.PageController.search(params)
    end
    {:noreply, assign(socket, page_content: page_content, page: page, changeset: Wikisource.SearchQuery.changeset(query, %{query: query_string}))}
  end

  def handle_event("validate", value, socket) do

    # %{"search_query" =>  params } = value

    # do the deploy process
    {:noreply, assign(socket, dummy: true)}
  end

  @spec handle_params(any, any, any) :: {:noreply, any}
  def handle_params(params, _uri, socket) do
    case params do
      %{"page" => "" } ->
        {:noreply, socket}
      %{"page" => page } ->
        handle_event("page", %{"search_query" => %{ "page" => page } }, socket)
      _ ->
        {:noreply, socket}
    end
  end

end
