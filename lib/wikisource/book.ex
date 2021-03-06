defmodule Wikisource.Book do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset
  alias Wikisource.Book

  schema "books" do
    field :chapter_number, :integer, virtual: true
    field :html, :string
    field :info, :string
    field :name, :string
    field :preface, :string
    field :text, :string
    field :url, :string

    field :info_html, :string
    field :preface_html, :string

    belongs_to :book, Book, foreign_key: :parent_id
    has_many :chapters, Book, foreign_key: :parent_id

    field :info_highlight, :string, virtual: true
    field :name_highlight, :string, virtual: true
    field :preface_highlight, :string, virtual: true
    field :text_highlight, :string, virtual: true

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
