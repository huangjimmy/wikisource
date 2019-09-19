defmodule Wikisource.Session do
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]

  import Ecto.Changeset

  schema "sessions" do
    field :device_desc, :string
    field :device_id, Ecto.UUID
    field :device_type, :string
    field :session_id, Ecto.UUID

    field :delete_time, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:session_id, :device_id, :device_type, :device_desc])
    |> validate_required([:session_id, :device_id, :device_type, :device_desc])
    |> unique_constraint(:session_id)
  end
end
