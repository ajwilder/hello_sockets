defmodule Camp1.CampServer do
  alias Camp1.CampServer.CampSupervisor
  alias Camp1.Public

  def start_camp_supervisor(camp_id) do
    process_name = :"CampServerSupervisor-#{camp_id}"
    process = Process.whereis(process_name)
    case process do
      nil ->
        {:ok, supervisor} = CampSupervisor.start_server(camp_id)
        Process.unlink(supervisor)
      _ ->
        :ok
    end
  end

  # BOARD
  def get_board(camp_id) do
    process = get_process(camp_id, "CampBoardStash")
    {:ok, stash} = GenServer.call(process, :get_stash)
    stash
  end

  # CHILDREN
  def get_children(camp_id, :week, date, page) do
    process = get_process(camp_id, "CampCoreStash")
    date =
      date
      |> date_string_to_date
      |> Timex.beginning_of_week
      |> Date.to_string
    children = GenServer.call(process, {:get_children, :week, date, page})
    case children do
      nil ->
        children = Public.get_camp_children(camp_id, :week, date_string_to_date(date), page)
        GenServer.cast(process, {:put_children, :week, date, page, children})
        children
      children ->
        children
    end
  end
  def get_children(camp_id, :day, date, page) do
    process = get_process(camp_id, "CampCoreStash")
    children = GenServer.call(process, {:get_children, :day, date, page})
    case children do
      nil ->
        children = Public.get_camp_children(camp_id, :day, date_string_to_date(date), page)
        GenServer.cast(process, {:put_children, :day, date, page, children})
        children
      children ->
        children
    end
  end
  def get_children(camp_id, type, page) do
    process = get_process(camp_id, "CampCoreStash")
    children = GenServer.call(process, {:get_children, type, page})
    case children do
      nil ->
        children = Public.get_camp_children(camp_id, type, page)
        GenServer.cast(process, {:put_children, type, page, children})
        children
      children ->
        children
    end
  end

  # CORE DATA
  def get_camp_for_home_page(camp_id) do
    process = get_process(camp_id, "CampCoreStash")
    {:ok, camp} = GenServer.call(process, :get_camp_for_home_page)
    case camp do
      nil ->
        camp = Public.get_camp_for_home_page(camp_id)
        put_camp_for_home_page(camp, process)
        camp
      camp ->
        camp
    end
  end
  def get_core_camp_data(camp_id) do
    process = get_process(camp_id, "CampCoreStash")
    {:ok, core_data} = GenServer.call(process, :get_core_data)
    core_data
  end
  def get_basic_data(camp_id) do
    process = get_process(camp_id, "CampCoreStash")
    {:ok, basic_data} = GenServer.call(process, :get_basic_data)
    basic_data
  end

  # OPPONENTS
  def get_opponents(camp_id, type, page) do
    process = get_process(camp_id, "CampCoreStash")
    opponents = GenServer.call(process, {:get_opponents, type, page})
    case opponents do
      nil ->
        opponents = Public.get_camp_opponents(camp_id, type, page)
        GenServer.cast(process, {:put_opponents, type, page, opponents})
        opponents
      opponents ->
        opponents

    end
  end
  def get_reasons(camp_id, page) do
    process = get_process(camp_id, "CampCoreStash")
    reasons = GenServer.call(process, {:get_reasons, page})
    case reasons do
      nil ->
        reasons = Public.get_camp_reasons(camp_id, page)
        GenServer.cast(process, {:put_reasons, page, reasons})
        reasons
      reasons ->
        reasons
    end
  end

  # COMPARISON
  def get_camp_compare_raw_data(camp_id) do
    process = get_process(camp_id, "CampCompareStash")
    {:ok, camp_compare_raw_data} = GenServer.call(process, :get_camp_compare_raw_data)
    camp_compare_raw_data
  end
  def get_camp_disagreement_map(camp_id) do
    process = get_process(camp_id, "CampCompareStash")
    {:ok, disagreement_map} = GenServer.call(process, :get_camp_disagreement_map)
    disagreement_map
  end
  def get_camp_agreement_map(camp_id) do
    process = get_process(camp_id, "CampCompareStash")
    {:ok, agreement_map} = GenServer.call(process, :get_camp_agreement_map)
    agreement_map
  end



  # CASTS

  # CORE DATA
  def put_camp_for_home_page(camp, process) do
    GenServer.cast(process, {:put_camp_for_home_page, camp})
  end


  # PRIVATE
  defp get_process(camp_id, type) do
    start_camp_supervisor(camp_id)
    process_name = :"#{type}-#{camp_id}"
    Process.whereis(process_name)
  end

  defp date_string_to_date(date) do
    date =
      date
      |> String.split("-")
      |> Enum.map(&(String.to_integer &1))
    {:ok, date} = Date.new(Enum.at(date, 0), Enum.at(date, 1), Enum.at(date, 2))
    date
  end



end
