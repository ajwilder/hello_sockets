defmodule Camp1.CampHome do
  alias Camp1.CampHome.{OpponentView}

  defdelegate get_opponent_view(camp_id, opponent_id), to: OpponentView
end
