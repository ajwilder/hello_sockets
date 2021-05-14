defmodule Camp1.CampHome.OpponentViewServer do
  use GenServer
  alias Camp1.CampHome.OpponentView
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @reload 30 * 60 * 1000

  def start(%{name: name, opponent_view: opponent_view, camp_id: camp_id,
  opponent_id: opponent_id}) do
    GenServer.start(__MODULE__, %{opponent_view: opponent_view, camp_id: camp_id,
    opponent_id: opponent_id}, name: name, hibernate_after: @hibernate)
  end

  def init(state) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@reload, :reload)
    {:ok, state}
  end

  def handle_call(:get_opponent_view, _from, state = %{opponent_view: opponent_view}) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@reload, :reload)
    {:reply, {:ok, opponent_view}, state}
  end

  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end

  def handle_info(:reload, state =  %{camp_id: camp_id,
  opponent_id: opponent_id}) do
    opponent_view = OpponentView.create_opponent_view(camp_id, opponent_id)
    {:noreply, Map.put(state, :opponent_view, opponent_view)}
  end
end
