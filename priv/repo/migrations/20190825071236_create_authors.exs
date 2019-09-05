defmodule Wikisource.Repo.Migrations.CreateAuthors do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :name, :string
      add :zhs_name, :string
      add :zht_name, :string

      timestamps()
    end

    create unique_index(:authors, [:name])
  end
end
