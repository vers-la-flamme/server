defmodule ApiWeb.UserView do
  use ApiWeb, :view
  alias ApiWeb.UserView
  @moduledoc false

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{login: user.login,
      email: user.email,
      name: user.name}
  end

end
