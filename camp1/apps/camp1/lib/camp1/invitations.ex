defmodule Camp1.Invitations do
  alias Camp1.Invitations.{ChatInvitation, AppInvitation}
  alias Camp1.Repo

  def create_chat_invitation(attrs) do
    %ChatInvitation{}
    |> ChatInvitation.changeset(attrs)
    |> Repo.insert
  end

  def get_chat_invitation(id) do
    Repo.get(ChatInvitation, id)
  end

  def update_chat_invitation(id, attrs) do
    get_chat_invitation(id)
    |> ChatInvitation.changeset(attrs)
    |> Repo.update()
  end

  def create_app_invitation(attrs) do
    changeset = AppInvitation.changeset(%AppInvitation{}, attrs)
    IO.puts "checking changeset"
    case changeset.valid? do
      true ->
        Repo.insert(changeset)
      _ ->
        {:error, changeset}
    end


    # TODO: actually send these invites via email
  end
end
