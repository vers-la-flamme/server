defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    # plug Api.Json.CamelCaseDecoder
  end

  # pipeline :authenticated do
  #   plug Api.Auth.CheckToken
  # end

  scope "/", ApiWeb do
    pipe_through :api
    # post "/join", RegistrationController, :sign_up, as: :signup
    # post "/login", SessionController, :sign_in, as: :login
    # post "/reauth", SessionController, :refresh_token, as: :relogin
    # get "/session-status", SessionController, :is_authenticated, as: :session_status
    # get "/me", UserController, :get_current_user, as: :user
  end
end
