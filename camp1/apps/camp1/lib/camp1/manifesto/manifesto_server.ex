defmodule Camp1.Manifesto.ManifestoServer do
  alias Camp1.{CampServer, Manifesto}

  def get_live_manifesto(camp_id) do
    process = get_manifesto_process(camp_id)
    manifesto = GenServer.call(process, :get_live_manifesto)
    case manifesto do
      nil ->
        manifesto = Manifesto.get_live_manifesto(camp_id)
        GenServer.cast(process, {:put_live_manifesto, manifesto})
        manifesto
      manifesto ->
        manifesto
    end
  end

  def get_proposed(camp_id) do
    process = get_manifesto_process(camp_id)
    manifesto = GenServer.call(process, :get_proposed)
    case manifesto do
      nil ->
        manifesto = Manifesto.get_proposed(camp_id)
        GenServer.cast(process, {:put_proposed, manifesto})
        manifesto
      manifesto ->
        manifesto
    end
  end

  def get_history(camp_id) do
    process = get_manifesto_process(camp_id)
    history = GenServer.call(process, :get_history)
    case history do
      nil ->
        history = Manifesto.get_history(camp_id)
        GenServer.cast(process, {:put_history, history})
        history
      history ->
        history
    end
  end

  def get_version(camp_id, manifesto_id) do
    process = get_manifesto_process(camp_id)
    content = GenServer.call(process, {:get_version, manifesto_id})
    case content do
      nil ->
        content = Manifesto.get_version(manifesto_id)
        GenServer.cast(process, {:put_version, manifesto_id, content})
        content
      content ->
        content
    end

  end




  # HELPERS

  defp get_manifesto_process(camp_id) do
    process = Process.whereis(:"CampManifestoStash-#{camp_id}")
    case process do
      nil ->
        CampServer.start_camp_supervisor(camp_id)
        get_manifesto_process(camp_id)
      process ->
        process
    end
  end

end
