defmodule Camp1.Public.Upload do
  # alias Camp1.Public.Image
  # alias Camp1.Public.Document

  def sha256(chunks_enum) do
    chunks_enum
    |> Enum.reduce(
      :crypto.hash_init(:sha256),
      &(:crypto.hash_update(&2, &1))
    )
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end



end
