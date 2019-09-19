defmodule WikisourceWeb.Context do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn) |> IO.inspect
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current session_id context based on the authorization header
  """
  def build_context(conn) do
    with ["Session " <> session_id] <- get_req_header(conn, "authorization") do
      case :mnesia.dirty_read(Wikisource.SessionStore, session_id) do
        [] ->
          %{}
        [ {Wikisource.SessionStore, id, data, _} ] ->
          # update session last access timestamp
          :mnesia.transaction fn -> :mnesia.write({Wikisource.SessionStore, id, data, DateTime.utc_now() |> DateTime.to_unix}) end
          %{session_id: id, session_data: data}
        _ ->
          %{}
      end
    else
      _ -> %{}
    end
  end
end
