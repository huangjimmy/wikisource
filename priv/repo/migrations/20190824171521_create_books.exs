defmodule Wikisource.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :name, :string
      add :info, :text
      add :preface, :text
      add :text, :text
      add :html, :text
      add :url, :text
      add :parent_id, references(:books, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:books, [:url])
    create index(:books, [:parent_id])
  end
end
