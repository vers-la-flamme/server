defmodule ApiWeb.RegistrationController do
  use ApiWeb, :controller
  @moduledoc false

  alias Api.Accounts
  alias Api.Accounts.User

  action_fallback ApiWeb.FallbackController

  def sign_up(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.register_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", api_v1_user_path(conn, :get_current_user))
      |> render("success.json", user: user)
    end
  end
end
