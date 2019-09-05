defmodule WikisourceWeb.WikiController do
  use WikisourceWeb, :controller

  import Ecto.Query
  alias Wikisource.{Repo, Book}

  plug :put_layout, "wiki.html"

  def index(conn, _params) do
    render(conn, "index.html", path: conn.path_info)
  end

  def render_wiki(conn, url, template) do
    case Repo.one(from p in Book, where: p.url == ^url, select: {p.name, p.info_html, p.preface_html, p.html} ) do
      nil -> render(conn, "index.html", book: "404")
      {name, info, preface, html} -> render(conn, template, name: name, info: info, preface: preface, book: html)
    end
  end

  def join_path([ "" ]) do
    ""
  end

  def join_path([ "/" ]) do
    "/"
  end

  def join_path([ "/" | t ]) do
    "/" <> join_path(t)
  end

  def join_path([ h | [ a ] ]) do
    h <> "/" <> a
  end

  def join_path([ h | t ]) do
    h <> "/" <> join_path(t)
  end

  def book(conn, _) do
    url = "/" <> join_path(conn.path_info)
    render_wiki(conn, url, "book.html")
  end

  def page(conn, _) do
    url = "/" <> join_path(conn.path_info)
    render_wiki(conn, url, "book.html")
  end
end
