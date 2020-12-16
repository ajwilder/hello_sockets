defmodule HelloSocketsWeb.WildcardChannelTest do

  use HelloSocketsWeb.ChannelCase
  import ExUnit.CaptureLog
  alias HelloSocketsWeb.UserSocket
  describe  "join/3 success" do
    test "ok when number in the format a:b where b = 2a" do
      assert {:ok, _, %Phoenix.Socket{}} = socket(UserSocket, nil, %{}) |> subscribe_and_join("wild:2:4", %{})
    end
  end

  describe  "join/3 error" do
    test "error when number in the format a:b where b != 2a" do
      assert {:error, %{}} ==
        socket(UserSocket, nil, %{})
        |> subscribe_and_join("wild:1:4", %{})
    end
    test "error when 3 numbers are provided" do
      assert {:error, %{}} ==
        socket(UserSocket, nil, %{})
        |> subscribe_and_join("wild:1:2:4", %{})
    end
  end

  describe  "join/3 error causing crash" do
    test "error with an invalid format topic" do
      assert capture_log(fn ->
        socket(UserSocket, nil, %{}) |> subscribe_and_join("wild:invalid", %{})
      end) =~ "[error]"
    end
  end

  describe "handle_in ping" do
    test "a pong response is provided" do
      assert {:ok, _, socket} =
        socket(UserSocket, nil, %{})
        |> subscribe_and_join("wild:2:4", %{})

      ref = push(socket, "ping", %{})
      reply = %{ping: "pong"}
      assert_reply ref, :ok, ^reply
    end
  end


end
