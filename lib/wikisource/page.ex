defmodule Wikisource.Page do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset

  schema "pages" do
    field :downloaded, :integer
    field :html, :string
    field :url, :string, unique: true

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:url, :html, :downloaded])
    |> validate_required([:url, :downloaded])
    |> unique_constraint(:url)
  end
end
