defmodule Wikisource.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :url, :text
      add :html, :text
      add :downloaded, :integer, default: 0

      timestamps()
    end

    create unique_index(:pages, [:url])
  end
end
