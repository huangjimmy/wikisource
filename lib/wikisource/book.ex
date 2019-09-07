defmodule Wikisource.Book do
  use Ecto.Schema
  import Ecto.Changeset

  alias Wikisource.Book

  schema "books" do
    field :html, :string
    field :info, :string
    field :name, :string
    field :preface, :string
    field :text, :string
    field :url, :string

    field :info_html, :string
    field :preface_html, :string

    belongs_to :book, Book, foreign_key: :parent_id
    has_many :chapters, Book

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name, :info, :preface, :text, :html, :url, :info_html, :preface_html, :parent_id])
    |> validate_required([:name, :info, :preface, :text, :html, :url, :info_html, :preface_html])
    |> unique_constraint(:url)
    |> foreign_key_constraint(:parent_id)
  end
end
