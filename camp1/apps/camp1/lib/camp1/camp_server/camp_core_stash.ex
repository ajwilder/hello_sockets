defmodule Camp1.CampServer.CampCoreStash do
  use GenServer
  alias Camp1.Public
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @update 60 * 60 * 1000
  def start_link(%{name: name, camp_id: camp_id}) do
    camp_data = Public.calculate_and_update_camp_data(camp_id)
    GenServer.start_link(
      __MODULE__,
      %{
        camp_data: camp_data,
        camp: nil,
        camp_id: camp_id,
        children: %{},
        children_by_oldest: [],
        children_by_biggest: [],
        children_by_smallest: [],
        children_by_newest: [],
        reasons: [],
        children_by_week: %{},
        children_by_day: %{},
        opponents: %{},
        opponents_by_oldest: [],
        opponents_by_biggest: [],
        opponents_by_smallest: [],
        opponents_by_newest: [],
        opponents_by_week: %{},
        opponents_by_day: %{},
        expiries: %{}
      },
      name: name,
      hibernate_after: @hibernate
    )
  end

  def init(stash) do
    :timer.send_after(@update, :update_core_data)
    :timer.send_after(@timeout, :job_timeout)
    {:ok, stash}
  end


  # CALLS

  # CORE DATA
  def handle_call(:get_core_data, _from, stash = %{camp_data: camp_data}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, camp_data}, stash}
  end
  def handle_call(:get_camp_for_home_page, _from, stash = %{camp: camp}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, camp}, stash}
  end
  def handle_call(:get_basic_data, _from, stash = %{camp: camp, camp_data: %{member_count: member_count}, camp_id: camp_id,}) do
    :timer.send_after(@timeout, :job_timeout)
    case camp do
      nil ->
        camp = Public.get_camp_for_home_page(camp_id)
        stash = Map.put(stash, :camp, camp)
        payload = %{current_content: camp.current_content, id: camp.id, member_count: member_count}
        {:reply, {:ok, payload}, stash}
      camp ->
        payload = %{current_content: camp.current_content, id: camp.id, member_count: member_count}
        {:reply, {:ok, payload}, stash}
    end
  end


  # OPPONENTS
  def handle_call({:get_opponents, :biggest, page}, _from, stash = %{opponents_by_biggest: opponents_by_biggest, opponents: opponents}) do
    ids = Enum.at(opponents_by_biggest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> opponents[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_opponents, :biggest, page}, _from, stash = %{opponents_by_oldest: opponents_by_oldest, opponents: opponents}) do
    ids = Enum.at(opponents_by_oldest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> opponents[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_opponents, :biggest, page}, _from, stash = %{opponents_by_newest: opponents_by_newest, opponents: opponents}) do
    ids = Enum.at(opponents_by_newest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> opponents[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_opponents, :biggest, page}, _from, stash = %{opponents_by_smallest: opponents_by_smallest, opponents: opponents}) do
    ids = Enum.at(opponents_by_smallest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> opponents[id] end)
        {:reply, payload, stash}
    end
  end


  # CHILDREN
  def handle_call({:get_children, :newest, page}, _from, stash = %{children: children, children_by_newest: children_by_newest}) do
    ids = Enum.at(children_by_newest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> children[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_children, :oldest, page}, _from, stash = %{children: children, children_by_oldest: children_by_oldest}) do
    ids = Enum.at(children_by_oldest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> children[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_children, :biggest, page}, _from, stash = %{children: children, children_by_biggest: children_by_biggest}) do
    ids = Enum.at(children_by_biggest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> children[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_children, :smallest, page}, _from, stash = %{children: children, children_by_smallest: children_by_smallest}) do
    ids = Enum.at(children_by_smallest, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> children[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_children, :day, date, page}, _from, stash = %{children: children, children_by_day: children_by_day}) do
    day_children = Map.get(children_by_day, date, [])
    ids = Enum.at(day_children, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> children[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_children, :week, date, page}, _from, stash = %{children: children, children_by_week: children_by_week}) do
    day_children = Map.get(children_by_week, date, [])
    ids = Enum.at(day_children, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> children[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_reasons, page}, _from, stash = %{children: children, reasons: reasons}) do
    :timer.send_after(@timeout, :job_timeout)
    ids = Enum.at(reasons, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> children[id] end)
        {:reply, payload, stash}
    end
  end


  # CASTS

  def handle_cast({:put_camp_for_home_page, camp}, stash) do
    {:noreply, Map.put(stash, :camp, camp)}
  end


  # OPPONENTS
  def handle_cast({:put_opponents, :newest, page, new_opponents}, stash = %{opponents: opponents, opponents_by_newest: opponents_by_newest}) do
    opponents = put_new_children(opponents, new_opponents)
    ids = Enum.map(new_opponents, fn opponent -> opponent.id end)
    opponents_by_newest = put_new_child_ids(opponents_by_newest, ids, page)
    stash =
      stash
      |> Map.put(:opponents, opponents)
      |> Map.put(:opponents_by_newest, opponents_by_newest)
    {:noreply, stash}
  end
  def handle_cast({:put_opponents, :oldest, page, new_opponents}, stash = %{opponents: opponents, opponents_by_oldest: opponents_by_oldest}) do
    opponents = put_new_children(opponents, new_opponents)
    ids = Enum.map(new_opponents, fn opponent -> opponent.id end)
    opponents_by_oldest = put_new_child_ids(opponents_by_oldest, ids, page)
    stash =
      stash
      |> Map.put(:opponents, opponents)
      |> Map.put(:opponents_by_oldest, opponents_by_oldest)
    {:noreply, stash}
  end
  def handle_cast({:put_opponents, :smallest, page, new_opponents}, stash = %{opponents: opponents, opponents_by_smallest: opponents_by_smallest}) do
    opponents = put_new_children(opponents, new_opponents)
    ids = Enum.map(new_opponents, fn opponent -> opponent.id end)
    opponents_by_smallest = put_new_child_ids(opponents_by_smallest, ids, page)
    stash =
      stash
      |> Map.put(:opponents, opponents)
      |> Map.put(:opponents_by_smallest, opponents_by_smallest)
    {:noreply, stash}
  end
  def handle_cast({:put_opponents, :biggest, page, new_opponents}, stash = %{opponents: opponents, opponents_by_biggest: opponents_by_biggest}) do
    opponents = put_new_children(opponents, new_opponents)
    ids = Enum.map(new_opponents, fn opponent -> opponent.id end)
    opponents_by_biggest = put_new_child_ids(opponents_by_biggest, ids, page)
    stash =
      stash
      |> Map.put(:opponents, opponents)
      |> Map.put(:opponents_by_biggest, opponents_by_biggest)
    {:noreply, stash}
  end

  # CHILDREN
  def handle_cast({:put_children, :newest, page, new_children}, stash = %{children: children, children_by_newest: children_by_newest}) do
    children = put_new_children(children, new_children)
    ids = Enum.map(new_children, fn child -> child.id end)
    children_by_newest = put_new_child_ids(children_by_newest, ids, page)
    stash =
      stash
      |> Map.put(:children, children)
      |> Map.put(:children_by_newest, children_by_newest)
    {:noreply, stash}
  end
  def handle_cast({:put_children, :oldest, page, new_children}, stash = %{children: children, children_by_oldest: children_by_oldest}) do
    children = put_new_children(children, new_children)
    ids = Enum.map(new_children, fn child -> child.id end)
    children_by_oldest = put_new_child_ids(children_by_oldest, ids, page)
    stash =
      stash
      |> Map.put(:children, children)
      |> Map.put(:children_by_oldest, children_by_oldest)
    {:noreply, stash}
  end
  def handle_cast({:put_children, :biggest, page, new_children}, stash = %{children: children, children_by_biggest: children_by_biggest}) do
    children = put_new_children(children, new_children)
    ids = Enum.map(new_children, fn child -> child.id end)
    children_by_biggest = put_new_child_ids(children_by_biggest, ids, page)
    stash =
      stash
      |> Map.put(:children, children)
      |> Map.put(:children_by_biggest, children_by_biggest)
    {:noreply, stash}
  end
  def handle_cast({:put_children, :smallest, page, new_children}, stash = %{children: children, children_by_smallest: children_by_smallest}) do
    children = put_new_children(children, new_children)
    ids = Enum.map(new_children, fn child -> child.id end)
    children_by_smallest = put_new_child_ids(children_by_smallest, ids, page)
    stash =
      stash
      |> Map.put(:children, children)
      |> Map.put(:children_by_smallest, children_by_smallest)
    {:noreply, stash}
  end
  def handle_cast({:put_children, :day, date, page, new_children}, stash = %{children: children, children_by_day: children_by_day}) do
    children = put_new_children(children, new_children)
    ids = Enum.map(new_children, fn child -> child.id end)

    days_children = Map.get(children_by_day, date, [])
    days_children = put_new_child_ids(days_children, ids, page)
    children_by_day = Map.put(children_by_day, date, days_children)

    stash =
      stash
      |> Map.put(:children, children)
      |> Map.put(:children_by_day, children_by_day)
    {:noreply, stash}
  end
  def handle_cast({:put_children, :week, date, page, new_children}, stash = %{children: children, children_by_week: children_by_week}) do
    children = put_new_children(children, new_children)
    ids = Enum.map(new_children, fn child -> child.id end)

    weeks_children = Map.get(children_by_week, date, [])
    weeks_children = put_new_child_ids(weeks_children, ids, page)
    children_by_week = Map.put(children_by_week, date, weeks_children)

    stash =
      stash
      |> Map.put(:children, children)
      |> Map.put(:children_by_week, children_by_week)
    {:noreply, stash}
  end
  def handle_cast({:put_reasons, page, new_children}, stash = %{children: children, reasons: reasons}) do
    children = put_new_children(children, new_children)
    ids = Enum.map(new_children, fn child -> child.id end)
    reasons = put_new_child_ids(reasons, ids, page)
    stash =
      stash
      |> Map.put(:children, children)
      |> Map.put(:reasons, reasons)
    {:noreply, stash}
  end

  # INFO
  def handle_info(:update_core_data, stash = %{camp_id: camp_id}) do
    :timer.send_after(@update, :update_core_data)
    camp_data = Public.calculate_and_update_camp_data(camp_id)
    {:noreply, Map.put(stash, :camp_data, camp_data)}
  end

  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end



  # PRIVATE
  defp put_new_children(children, new_children)
  defp put_new_children(children, []), do: children
  defp put_new_children(children, [new_child | new_children]) do
    put_new_children(
      Map.put(children, new_child.id, new_child),
      new_children
    )
  end

  defp put_new_child_ids(main_list, new_sublist, page)
  defp put_new_child_ids(main_list, new_sublist, page) when (length(main_list) <= page) do
    List.insert_at(main_list, page, new_sublist)
  end
  defp put_new_child_ids(main_list, _new_sublist, page) do
    List.insert_at(main_list, page, nil)
  end



end
