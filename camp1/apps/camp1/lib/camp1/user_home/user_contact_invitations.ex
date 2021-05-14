defmodule Camp1.UserHome.UserContactInvitations do
  import Ecto.Query, warn: false
  alias Camp1.{Repo, UserHome}
  alias Camp1.Invitations.{ContactInvitation, AppInvitation}

  def get_user_contact_invite(user_id) do
    %{
      sub_menu: :invite,
      contacts: nil,
      handle: UserHome.get_default_user_handle(user_id)
    }
  end

  def get_user_contact_invitations(user_id) do
    sent_invitations =
      get_sent_invitations(user_id) ++ get_sent_app_invitations(user_id)
      |> Enum.sort_by(fn invitation ->
        invitation.inserted_at
      end, :desc)
    received_invitations =
      get_received_invitations(user_id) ++ get_received_app_invitations(user_id)
      |> Enum.sort_by(fn invitation ->
        invitation.inserted_at
      end, :desc)
    %{
      contacts: nil,
      sub_menu: :invitations,
      sent_invitations: sent_invitations,
      received_invitations: received_invitations,
    }

  end

  defp get_received_invitations(user_id) do
    q = from invitation in ContactInvitation,
      where: invitation.user_id == ^user_id,
      select: %{status: invitation.status, source: invitation.source, handle: invitation.inviter_handle, inserted_at: invitation.inserted_at}
    Repo.all(q)
  end
  defp get_sent_invitations(user_id) do
    q = from invitation in ContactInvitation,
      where: invitation.inviter_id == ^user_id,
      select: %{status: invitation.status, source: invitation.source, handle: invitation.user_handle, inserted_at: invitation.inserted_at}
    Repo.all(q)
  end
  defp get_sent_app_invitations(user_id) do
    q = from invitation in AppInvitation,
      where: invitation.inviter_id == ^user_id,
      select: %{status: invitation.status, source: :app, email: invitation.email, inserted_at: invitation.inserted_at}
    Repo.all(q)
  end
  defp get_received_app_invitations(user_id) do
    q = from invitation in AppInvitation,
      where: invitation.user_id == ^user_id,
      select: %{status: invitation.status, source: :app, email: invitation.inviter_email, inserted_at: invitation.inserted_at}
    Repo.all(q)
  end
end
