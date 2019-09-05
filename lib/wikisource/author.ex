defmodule Wikisource.Author do
  use Ecto.Schema
  import Ecto.Changeset


  schema "authors" do
    field :name, :string
    field :zhs_name, :string
    field :zht_name, :string

    timestamps()
  end

  @doc false
  def changeset(author, attrs) do
    author
    |> cast(attrs, [:name, :zhs_name, :zht_name])
    |> validate_required([:name, :zhs_name, :zht_name])
    |> unique_constraint(:name)
  end
end
