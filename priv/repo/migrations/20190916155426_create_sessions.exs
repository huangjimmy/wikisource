defmodule Wikisource.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :session_id, :uuid
      add :device_id, :uuid
      add :device_type, :string
      add :device_desc, :string

      add :delete_time, :naive_datetime

      timestamps()
    end

    create unique_index(:sessions, [:session_id])
  end
end
