defmodule WikisourceWeb.Resolvers.SessionResolver do
  import Ecto.Changeset, only: [change: 2]
  alias Wikisource.{Session, Repo}

  @invalid_session_error %{message: "invalid session", error_code: 401}
  @session_not_found %{message: "session not found", error_code: 404}
  @session_invalid_parameter %{message: "invalid parameters, please note that session_id must match that in http authorization header", error_code: 412}
  @create_invalid_parameter %{message: "invalid parameters, device_id must be uuid and non null, device_type and device_desc must be nonnull", error_code: 412}

  def create(_parent, _args, %{context: %{session_id: session_id}} = _resolutions) do
    # if a session is still valid, return the existing session_id instead of creating a new one
    {:ok, %{session_id: session_id}}
  end

  def create(_parent, args, _resolutions) do

    case args do
      %{:device_id => device_id, :device_type => device_type, :device_desc => device_desc} ->
        session_id = UUID.uuid1()
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
            _ -> {:error, @create_invalid_parameter}
          end
        rescue _e ->
          {:error, @create_invalid_parameter}
        end
      _ ->  {:error, @session_not_found}
    end
  end

  def delete(_parent, _args, %{context: %{session_id: session_id}} = _resolutions) do
    case session_id do
      nil -> {:error, @session_invalid_parameter}
      "" -> {:error, @session_invalid_parameter}
      _ ->
        case Repo.get_by(Session, session_id: session_id) do
          nil -> {:error, @session_not_found}
          session ->
            Repo.update change(session, delete_time: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second))

            :mnesia.transaction fn ->
              :mnesia.delete({Wikisource.SessionStore, session_id})
            end

            {:ok, %{session_id: ""}}
        end
    end
  end

  def delete(_parent, _args, _resolutions) do
    {:error, @invalid_session_error}
  end
end
