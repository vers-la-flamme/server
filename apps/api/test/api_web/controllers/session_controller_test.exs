defmodule ApiWeb.SessionControllerTest do
  use ApiWeb.ConnCase

  @sign_up_payload %{
    login: "verslaflam.me",
    email: "email@verslaflam.me",
    first_name: "john",
    last_name: "doe",
    password: "some password",
    password_confirmation: "some password"
  }

  @sign_in_payload %{
    login: "verslaflam.me",
    password: "some password",
    device_id: "some device",
    platform_id: "ios"
  }

  @refresh_token_payload %{
    bearer: "none",
    device_id: "some device",
    platform_id: "ios"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "register and login" do
    test "registers and logs user in when data is valid", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: @sign_in_payload
      assert %{"status" => "ok"} = json_response(conn, 200)
      assert json_response(conn, 200)["data"]["token"] != ""
    end

    test "registers and logs user in when data is valid but login case differs", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: %{@sign_in_payload | login: "verslaflam.ME"}
      assert %{"status" => "ok"} = json_response(conn, 200)
      assert json_response(conn, 200)["data"]["token"] != ""
    end

    test "returns valid JWT token that successfully authorizes a protected resource request", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: @sign_in_payload
      assert %{"status" => "ok"} = json_response(conn, 200)
      assert json_response(conn, 200)["data"]["email"] == "email@verslaflam.me"

      jwt = json_response(conn, 200)["data"]["token"]
      conn = get authenticated(conn, jwt), api_v1_session_status_path(conn, :is_authenticated)
      assert json_response(conn, 200)["status"] == "ok"
    end

    test "renders login error when login is invalid", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: %{@sign_in_payload | login: "invalid"}
      assert %{"errors" => %{"status" => "unauthorized"}} = json_response(conn, 401)
    end

    test "renders login error when password is invalid", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: %{@sign_in_payload | password: "invalid"}
      assert %{"errors" => %{"status" => "unauthorized"}} = json_response(conn, 401)
    end
  end

  describe "register, login and update token" do
    test "refreshes token given a valid token and a new token becomes valid to refresh again", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: @sign_in_payload
      assert %{"status" => "ok"} = json_response(conn, 200)
      token = json_response(conn, 200)["data"]["token"]

      conn = post authenticated(conn, token), api_v1_relogin_path(conn, :refresh_token),
        session: %{@refresh_token_payload | bearer: token}

      assert %{"status" => "ok"} = json_response(conn, 200)
      new_token_1 = json_response(conn, 200)["data"]["token"]
      assert token != new_token_1

      conn = post authenticated(conn, new_token_1), api_v1_relogin_path(conn, :refresh_token),
        session: %{@refresh_token_payload | bearer: new_token_1}

      assert %{"status" => "ok"} = json_response(conn, 200)
      new_token_2 = json_response(conn, 200)["data"]["token"]
      assert new_token_1 != new_token_2
    end

    test "fails to re-generate token twice based on the same token", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: @sign_in_payload
      assert %{"status" => "ok"} = json_response(conn, 200)
      token = json_response(conn, 200)["data"]["token"]

      conn = post authenticated(conn, token), api_v1_relogin_path(conn, :refresh_token),
        session: %{@refresh_token_payload | bearer: token}

      assert %{"status" => "ok"} = json_response(conn, 200)
      new_token = json_response(conn, 200)["data"]["token"]

      assert new_token != token

      conn = post authenticated(conn, token), api_v1_relogin_path(conn, :refresh_token),
        session: %{@refresh_token_payload | bearer: token}

      assert response(conn, 401)
    end

    test "authorizes a protected resource request with a refreshed token", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: @sign_in_payload
      assert %{"status" => "ok"} = json_response(conn, 200)
      token = json_response(conn, 200)["data"]["token"]

      conn = post authenticated(conn, token), api_v1_relogin_path(conn, :refresh_token),
        session: %{@refresh_token_payload | bearer: token}

      assert %{"status" => "ok"} = json_response(conn, 200)
      new_token = json_response(conn, 200)["data"]["token"]

      assert new_token != token
      conn = get authenticated(conn, new_token), api_v1_session_status_path(conn, :is_authenticated)
      assert json_response(conn, 200)["status"] == "ok"
    end

    test "fails to re-generate token given valid token but different device id", %{conn: conn} do
      conn = post conn, api_v1_signup_path(conn, :sign_up), user: @sign_up_payload
      assert %{"status" => "ok"} = json_response(conn, 201)

      conn = post conn, api_v1_login_path(conn, :sign_in), session: @sign_in_payload
      assert %{"status" => "ok"} = json_response(conn, 200)
      token = json_response(conn, 200)["data"]["token"]

      conn = post authenticated(conn, token), api_v1_relogin_path(conn, :refresh_token),
        session: %{@refresh_token_payload | bearer: token, device_id: "other"}

      assert response(conn, 401)
    end

    test "fails to re-generate token given an unauthenticated request", %{conn: conn} do
      conn = post conn, api_v1_relogin_path(conn, :refresh_token), session: @refresh_token_payload
      assert response(conn, 401)
    end
  end

  defp authenticated(conn, jwt) do
    conn |> recycle |> put_req_header("authorization", "Bearer #{jwt}")
  end
end
