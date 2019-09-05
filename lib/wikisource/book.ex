defmodule Wikisource.Book do
  use Ecto.Schema
  import Ecto.Changeset


  schema "books" do
    field :html, :string
    field :info, :string
    field :name, :string
    field :preface, :string
    field :text, :string
    field :url, :string

    field :info_html, :string
    field :preface_html, :string

    field :parent_id, :id

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name, :info, :preface, :text, :html, :url, :info_html, :preface_html])
    |> validate_required([:name, :info, :preface, :text, :html, :url, :info_html, :preface_html])
    |> unique_constraint(:url)
  end
end
