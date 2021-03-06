defmodule POABackend.CustomHandler.REST.Plugs.Authorization do
  @moduledoc false

  alias POABackend.Auth

  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    import Plug.Conn

    with {"authorization", "Bearer " <> jwt_token} <- List.keyfind(conn.req_headers, "authorization", 0),
         true <- Auth.valid_token?(jwt_token)
    do
      conn
    else
      {:error, :token_expired} ->
        conn
        |> send_resp(401, Poison.encode!(%{error: :token_expired}))
        |> halt
      _error ->
        conn
        |> send_resp(401, "")
        |> halt
    end
  end

end
