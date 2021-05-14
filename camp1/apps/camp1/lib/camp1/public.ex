defmodule Camp1.Public do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Ecto.Multi
  alias Camp1.Reactions.Rating
  alias Camp1.Topics.Subject
  alias Camp1.Public.{Camp, CampOpponentRelationship, CampChildRelationship, CampData, Image, Upload, Document}


  # DELEGATIONS
  defdelegate calculate_and_update_camp_data(camp_id), to: Camp


  # BASIC
  def list_camps do
    Repo.all(Camp)
  end
  def get_camp!(id), do: Repo.get!(Camp, id)
  def get_camp(id), do: Repo.get(Camp, id)
  def get_core_camp_data(id) do
     Repo.get(Camp, id)
     |> Repo.preload(:opponents)
     |> Repo.preload(:children)
     |> Repo.preload(:subject)
     |> Repo.preload(:top_subject)
     |> Repo.preload(:camp_data)
     |> Repo.preload(subject: :parent)
     |> Repo.preload(:parent)
  end
  def get_camp_by(attrs) do
    Repo.get_by(Camp, attrs)
  end


  # HOME PAGE DATA
  def get_camp_for_home_page(id) do
    query_camp_for_home_page(id)
    |> Repo.all
    |> List.first
  end
  def old_camp_for_home_page(id) do
    Repo.get(Camp, id) |> Repo.preload(:subject) |> Repo.preload(:top_subject) |> Repo.preload(subject: :parent) |> Repo.preload(:parent)
  end


  # CHILDREN
  def get_camp_children(camp_id, type, page)
  def get_camp_children(camp_id, type, page) do
    query_camp_children(camp_id, type, page)
    |> Repo.all
  end

  def get_camp_children(camp_id, type, date, page)
  def get_camp_children(camp_id, :week, date, page) do
    query_camp_children_by_range(camp_id, start_of_week(date), end_of_week(date), page)
    |> Repo.all
  end
  def get_camp_children(camp_id, :day, date, page) do
    query_camp_children_by_range(camp_id, start_of_day(date), end_of_day(date), page)
    |> Repo.all
  end

  # OPPONENTS
  def get_camp_opponents(camp_id, type, page)
  def get_camp_opponents(camp_id, type, page) do
    query_camp_opponents(camp_id, type, page)
    |> Repo.all
  end
  def get_camp_reasons(camp_id, page) do
    query_camp_reasons(camp_id, page)
    |> Repo.all
  end

  # DATA
  def get_camp_data(id) do
    Repo.get_by(CampData, %{camp_id: id})
  end
  def get_camp_comparison_map(id) do
    map = query_camp_comparison_map(id)
      |> Repo.all
      |> List.first

    map
    |> Map.keys
    |> Enum.reduce(%{}, fn key, new_map ->
      Map.put(
        new_map,
        String.to_integer(key),
        convert_subject_comparison_map_to_integers(map[key])
      )
    end)
  end
  defp convert_subject_comparison_map_to_integers(map) do
    map
    |> Map.keys
    |> Enum.reduce(%{}, fn id, new_map ->
      Map.put(
        new_map,
        String.to_integer(id),
        convert_comparison_map_to_atoms(map[id])
      )
    end)
  end
  defp convert_comparison_map_to_atoms(map) do
    map
    |> Map.keys
    |> Enum.reduce(%{}, fn key, new_map ->
      Map.put(
        new_map,
        String.to_atom(key),
        map[key]
      )
    end)
  end

  # MEMBER DATA
  def get_camp_member_ids(camp_id) do
    camp_id
    |> query_db_for_camp_member_ids()
    |> Repo.all
  end


  # CREATE CAMPS
  def create_camp(attrs \\ %{}) do
    %Camp{}
    |> Camp.create_changeset(attrs)
    |> Repo.insert()
  end
  def create_camp_with_opponent(attrs, opponent_id) do
    Multi.new()
    |> Multi.insert(:camp, Camp.create_changeset(%Camp{}, attrs))
    |> Multi.merge(fn %{camp: camp} ->
      Multi.new()
      |> Multi.insert(:camp_opponent, CampOpponentRelationship.changeset(
        %CampOpponentRelationship{},
        %{
          opponent_id: opponent_id,
          camp_id: camp.id
        }
      ))
    end)
    |> Repo.transaction()
  end
  def create_camp_with_parent(attrs, type, parent_id) do
    Multi.new()
    |> Multi.insert(:camp, Camp.create_changeset(%Camp{}, attrs))
    |> Multi.merge(fn %{camp: camp} ->
      Multi.new()
      |> Multi.insert(:camp_relationship, CampChildRelationship.changeset(
        %CampChildRelationship{},
        %{
          parent_id: parent_id,
          child_id: camp.id,
          type: type
        }
      ))
    end)
    |> Repo.transaction()
  end
  def create_camp_opponent_relationship(attrs) do
    %CampOpponentRelationship{}
    |> CampOpponentRelationship.changeset(attrs)
    |> Repo.insert
  end


  # UPDATES
  def update_camp(%Camp{} = camp, attrs) do
    camp
    |> Camp.update_changset(attrs)
    |> Repo.update()
  end
  def delete_camp(%Camp{} = camp) do
    Repo.delete(camp)
  end
  def update_camp_data(%CampData{} = camp_data, attrs) do
    camp_data
    |> CampData.changeset(attrs)
    |> Repo.update()
  end


  # UPLOADS
  def create_image_upload_from_plug_upload(_repo, _vote, upload) do
    create_image_upload_from_plug_upload(upload)
  end
  def create_image_upload_from_plug_upload(%Plug.Upload{
    filename: _filename,
    path: tmp_path,
    content_type: "image/" <> _img_type
  }) do
    hash =
      File.stream!(tmp_path, [], 2048)
      |> Upload.sha256()
    with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
      {:ok, image} <-
        %Image{}
        |> Image.changeset(%{
          hash: hash, size: size })
        |> Repo.insert(),
      :ok <- File.cp(
          tmp_path,
          Image.local_path(image.id)
       ),
       {:ok, _thumbnail} <-
         Image.create_thumbnail(image)
    do
      {:ok, image}
    else
      {:error, _reason}= error -> error
    end
  end

  def create_document_upload_from_plug_upload(_repo, _vote, upload) do
    create_document_upload_from_plug_upload(upload)
  end
  def create_document_upload_from_plug_upload(%Plug.Upload{
    filename: _filename,
    path: tmp_path,
    content_type: "application/pdf"
  }) do
    hash =
      File.stream!(tmp_path, [], 2048)
      |> Upload.sha256()
    with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
      {:ok, document} <-
        %Document{}
        |> Document.changeset(%{
          hash: hash, size: size })
        |> Repo.insert(),
      :ok <- File.cp(
          tmp_path,
          Document.local_path(document.id)
       ),
       {:ok, _thumbnail} <-
         Document.create_thumbnail(document)
    do
      {:ok, document}
    else
      {:error, _reason}= error -> error
    end
  end



  # PRIVATE QUERY FUNCTIONS
  defp query_db_for_camp_member_ids(camp_id) do
    from rate in Rating,
      where: rate.camp_id == ^camp_id,
      where: rate.value in [4,5],
      select: rate.user_id
  end

  defp query_camp_children_by_range(camp_id, start_time, end_time, page) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      where: rel.inserted_at > ^start_time,
      where: rel.inserted_at < ^end_time,
      join: camp in Camp,
      where: rel.child_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: {:desc, data.member_count},
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end
  defp query_camp_children(camp_id, :newest, page) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      join: camp in Camp,
      where: rel.child_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: {:desc, camp.inserted_at},
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end
  defp query_camp_children(camp_id, :oldest, page) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      join: camp in Camp,
      where: rel.child_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: camp.inserted_at,
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end
  defp query_camp_children(camp_id, :biggest, page) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      join: camp in Camp,
      where: rel.child_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: {:desc, data.member_count},
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end
  defp query_camp_children(camp_id, :smallest, page) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      join: camp in Camp,
      where: rel.child_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: data.member_count,
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end

  defp query_camp_opponents(camp_id, :newest, page) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id == ^camp_id,
      join: camp in Camp,
      where: rel.opponent_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: {:desc, camp.inserted_at},
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end
  defp query_camp_opponents(camp_id, :oldest, page) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id == ^camp_id,
      join: camp in Camp,
      where: rel.opponent_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: camp.inserted_at,
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end
  defp query_camp_opponents(camp_id, :smallest, page) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id == ^camp_id,
      join: camp in Camp,
      where: rel.opponent_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: data.member_count,
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end
  defp query_camp_opponents(camp_id, :biggest, page) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id == ^camp_id,
      join: camp in Camp,
      where: rel.opponent_id == camp.id,
      join: data in CampData,
      where: data.id == camp.id,
      order_by: {:desc, data.member_count},
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end

  defp query_camp_reasons(camp_id, page) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      where: rel.type == :reason,
      join: data in CampData,
      where: data.id == rel.child_id,
      order_by: {:desc, data.member_count},
      join: camp in Camp,
      where: camp.id == rel.child_id,
      limit: 20,
      offset: (^page * 20),
      select: %{
        current_content: camp.current_content,
        id: camp.id,
        inserted_at: camp.inserted_at,
        member_count: data.member_count,
        opponent_count: data.opponent_count,
        child_count: data.child_count,
        type: camp.type

      }
  end

  defp query_camp_comparison_map(camp_id) do
    from data in CampData,
      where: data.camp_id == ^camp_id,
      select: data.comparison_map
  end

  defp query_camp_for_home_page(camp_id) do
    from camp in Camp,
      where: camp.id == ^camp_id,
      join: data in CampData,
      where: data.camp_id == ^camp_id,
      join: subject in Subject,
      where: subject.id == camp.subject_id,
      left_join: subject_parent in assoc(subject, :parent),
      left_join: rel in assoc(camp, :camp_parent_relationship),
      left_join: parent in assoc(camp, :parent),
      select: %{
        inserted_at: camp.inserted_at,
        id: camp.id,
        parent_id: rel.parent_id,
        parent: %{
          id: parent.id,
          current_content: parent.current_content
        },
        current_content: camp.current_content,
        member_count: data.member_count,
        message_count: data.message_count,
        child_count: data.child_count,
        post_count: data.post_count,
        image_count: data.image_count,
        opponent_count: data.opponent_count,
        subject: %{
          content: subject.content,
          parent_id: subject.parent_id,
          parent: %{
            content: subject_parent.content,
            id: subject_parent.id
          }
        }
      }
  end

  defp query_document_content(camp_id, document_id) do
    from c in Comment,
      where: c.camp_id == ^camp_id,
      where: c.document_id == ^ document_id,
      select: c.content
  end

  # HELPERS
  defp start_of_day(date) do
    date
    |> Timex.to_datetime
    |> Timex.beginning_of_day
    |> Timex.shift(hours: 9)
  end
  defp start_of_week(date) do
    date
    |> Timex.to_datetime
    |> Timex.beginning_of_week
    |> Timex.shift(hours: 9)
  end
  defp end_of_day(date) do
    date
    |> Timex.to_datetime
    |> Timex.end_of_day
    |> Timex.shift(hours: 9)
  end
  defp end_of_week(date) do
    date
    |> Timex.to_datetime
    |> Timex.end_of_week
    |> Timex.shift(hours: 9)
  end
end
