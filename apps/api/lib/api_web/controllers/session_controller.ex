defmodule ApiWeb.SessionController do
  use ApiWeb, :controller
  @moduledoc false

  alias Api.Auth.Token
  alias Api.Accounts.User
  alias Api.Accounts.Session

  action_fallback ApiWeb.FallbackController

  def sign_in(conn, %{"session" => %{"login" => login, "password" => pass,
    "device_id" => device_id, "platform_id" => platform_id}}) do
    with {:ok, user} <- User.find_and_confirm_password(login, pass),
         {:ok, permissions} <- Token.get_permissions_for(user),
         {:ok, jwt, _full_claims} <- Token.encode_and_sign(user, %{}, permissions: permissions),
         {:ok, jwt} <- Session.update_token_for_device(user.id, device_id, platform_id, jwt),
    do: render(conn, "sign_in.json", user: user, jwt: jwt)
  end

  def refresh_token(conn, %{"session" => %{"bearer" => old_token,
    "device_id" => device_id, "platform_id" => platform_id}}) do
    with {:ok, user} <- User.find_user_for_session(device_id, old_token),
         {:ok, permissions} <- Token.get_permissions_for(user),
         {:ok, jwt, _full_claims} <- Token.encode_and_sign(user, %{}, permissions: permissions),
         {:ok, jwt} <- Session.update_token_for_device(user.id, device_id, platform_id, jwt),
    do: render(conn, "refresh_token.json", user: user, jwt: jwt)
  end

  def is_authenticated(conn, _params) do
    conn
    |> put_status(:ok)
    |> render(ApiWeb.SessionView, "session_status.json")
  end
end
