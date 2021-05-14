defmodule HelloSocketsWeb.PingChannel do
  use Phoenix.Channel

  def join(_topic, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{ping: "pong"}}, socket}
  end

  def handle_in("param_ping", %{"error" => true}, socket) do
    {:reply, {:error, %{reason: "You asked for this!"}}, socket}
  end

  def handle_in("param_ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("pong", _payload, socket) do
    {:noreply, socket}
  end
end
