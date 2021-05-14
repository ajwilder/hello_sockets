defmodule Camp1.Survey.CampRatings do
  use GenServer
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000

  def start(%{name: name, prq: prq}) do
    GenServer.start(__MODULE__, %{prq: prq}, name: name, hibernate_after: @hibernate)
  end

  def init(state) do
    :timer.send_after(@timeout, :job_timeout)
    {:ok, state}
  end

  def handle_call(:get_prq, _from, state = %{prq: prq}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, prq}, state}
  end

  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end
end
