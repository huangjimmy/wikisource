defmodule WikisourceWeb.Context do
  @behaviour Plug

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context) |>
    Plug.Conn.register_before_send(fn conn ->
      case conn.resp_body do
        "{\"data\":{\"createSession\":{\"sessionId\":\"" <> _ ->
          case Jason.decode(conn.resp_body) do
            {:ok, %{"data" => %{"createSession" => %{"sessionId" => session_id} } } } ->
              IO.puts(conn.resp_body)
              put_resp_cookie(conn, "session_id", session_id, httpOnly: true, max_age: 86400*3660)
              # session_id is stored in httpOnly cookie, the cookie itself is valid for 10 years,
              # but the session will expire after 7200 seconds from its last access
            _ -> conn
          end
        "{\"data\":{\"deleteSession\":{\"sessionId\":\"" <> _ ->
          IO.puts(conn.resp_body)
          put_resp_cookie(conn, "session_id", "", httpOnly: true)
        _ -> conn
      end
    end)
  end

  @doc """
  Return the current session_id context based on the authorization header or cookie
  """
  def session_id_from_context(conn) do

    with ["Session " <> session_id] <- get_req_header(conn, "authorization") do
      {:ok, session_id}
    else
      _ ->
        conn = Plug.Conn.fetch_cookies(conn)
        case conn.req_cookies["session_id"] do
        nil -> {:error, nil}
        session_id -> {:ok, session_id}
      end
    end
  end

  def build_context(conn) do

    with {:ok, session_id} <- session_id_from_context(conn) do
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
