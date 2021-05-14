defmodule Camp1.Manifesto.ManifestoStash do
  use GenServer
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @update 60 * 60 * 1000


  def start_link(%{name: name, camp_id: camp_id}) do
    GenServer.start_link(
      __MODULE__,
      %{
        camp_id: camp_id,
        live_manifesto: nil,
        proposed: nil,
        history: nil,
        versions: %{},
        current_votes: %{
          yes: 0,
          no: 0,
        }
      },
      name: name,
      hibernate_after: @hibernate)
  end

  def init(stash) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@update, :update_stash)
    {:ok, stash}
  end


  # GETTERS
  def handle_call(:get_live_manifesto, _from, stash = %{live_manifesto: live_manifesto}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, live_manifesto, stash}
  end

  def handle_call(:get_proposed, _from, stash = %{proposed: proposed}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, proposed, stash}
  end

  def handle_call(:get_history, _from, stash = %{history: history}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, history, stash}
  end

  def handle_call({:get_version, id}, _from, stash = %{versions: versions}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, Map.get(versions, id), stash}
  end


  # PUTTERS

  def handle_cast({:put_live_manifesto, manifesto}, stash) do
    {:noreply, %{stash | live_manifesto: manifesto}}
  end

  def handle_cast({:put_proposed, manifesto}, stash) do
    {:noreply, %{stash | proposed: manifesto}}
  end

  def handle_cast({:put_history, history}, stash) do
    {:noreply, %{stash | history: history}}
  end

  def handle_cast({:put_version, id, content}, stash = %{versions: versions}) do
    versions = Map.put(versions, id, content)
    {:noreply, %{stash | versions: versions}}
  end



  # INFO
  def handle_info(:update_stash, stash) do
    :timer.send_after(@update, :update_stash)
    {:noreply, stash}
  end
  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end


end
