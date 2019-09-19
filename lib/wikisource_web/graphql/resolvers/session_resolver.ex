defmodule WikisourceWeb.Resolvers.SessionResolver do
  import Ecto.Changeset, only: [change: 2]
  alias Wikisource.{Session, Repo}

  def create(_parent, args, _resolutions) do
    case args do
      %{:device_id => device_id, :device_type => device_type, :device_desc => device_desc} ->
        session_id = UUID.uuid1()
        IO.inspect(session_id)
        try do
          case Repo.insert(%Session{
            session_id: session_id,
            device_id: device_id,
            device_type: device_type,
            device_desc: device_desc
          }) do
            {:ok, _} ->
              :mnesia.transaction fn ->
                :mnesia.write({Wikisource.SessionStore, session_id,
                %{device_id: device_id, device_type: device_type, device_desc: device_desc},
                DateTime.utc_now() |> DateTime.to_unix})
              end
              {:ok, %{session_id: session_id}}
            _ -> {:error, message: "invalid parameters"}
          end
        rescue _e ->
          {:error, message: "invalid parameters"}
        end
      _ ->  {:error, message: "not found"}
    end
  end

  def delete(_parent, args, _resolutions) do
    case args do
      %{:session_id => session_id} ->
        case Repo.get_by(Session, session_id: session_id) do
          nil -> {:error, message: "not found"}
          session ->
            Repo.update change(session, delete_time: DateTime.utc_now())

            :mnesia.transaction fn ->
              :mnesia.delete({Wikisource.SessionStore, session_id})
            end

            {:ok, %{session_id: ""}}
        end
      _ ->  {:error, message: "not found"}
    end
  end

end
