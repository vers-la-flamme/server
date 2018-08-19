defmodule Api.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Accounts.Session
  @moduledoc """
  The User model.
  """

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :login, :string
    field :email, :string
    field :name, :string

    field :password, :string, virtual: true # virtual - i.e. not stored in db
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string

    has_many :active_sessions, Session

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:login, :email, :name, :password])
    |> validate_required([:login, :password])
    |> validate_changeset
    |> validate_password
  end

  @doc false
  def identity_registration_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:login, :email, :name, :password, :password_confirmation])
    |> validate_required([:login, :password, :password_confirmation])
    |> validate_confirmation(:password)
    |> validate_changeset
    |> validate_password
  end

  defp validate_changeset(user) do
    user
    |> validate_length(:email, min: 5, max: 255)
    |> validate_format(:email, ~r/@/)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:login)
    |> unique_constraint(:email)
    |> validate_length(:login, min: 3, max: 16)
    |> validate_format(:login, ~r/^[a-zA-Z][a-zA-Z0-9]*[.-]?[a-zA-Z0-9]+$/,
      [message: "only letters and numbers allowed, should start with a letter, only one char of (.-) allowed"])
    |> validate_length(:password, min: 8)
    |> validate_format(:password, ~r/^(?=.*[a-zA-Z]).*/,
      [message: "must include at least one letter"])
    |> generate_password_hash
  end

  defp validate_password(user) do
    user
    |> validate_length(:password, min: 8)
    |> validate_format(:password, ~r/^(?=.*[a-zA-Z]).*/,
      [message: "must include at least one letter"])
    |> generate_password_hash
  end

  defp generate_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Pbkdf2.hashpwsalt(password))
      _ ->
        changeset
    end
  end

  def find_and_confirm_password(login, password) do
    case Repo.get_by(User, login: String.downcase(login)) do
      nil ->
        {:error, :login_not_found}
      user ->
        if user.password_hash != "" && Comeonin.Pbkdf2.checkpw(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :login_failed}
        end
    end
  end

  def find_user_for_session(device_id, token) do
    query = from u in User,
          join: s in Session, on: s.user_id == u.id,
          where: s.device_id == ^device_id and s.token == ^token,
          select: struct(u, [:id, :login, :email])
    case Repo.one(query) do
      nil -> {:error, :session_not_found}
      user -> {:ok, user}
    end
  end
end
