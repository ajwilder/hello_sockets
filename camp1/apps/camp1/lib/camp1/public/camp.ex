defmodule Camp1.Public.Camp do
  import Ecto.Query, warn: false
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.PublicChat.PublicMessage
  alias Camp1.Public.{CampChildRelationship, CampOpponentRelationship, CampData}
  alias Camp1.Topics.{Subject}
  alias Camp1.Reactions.Rating
  alias Camp1.{Repo, Public}
  alias Camp1.Board.Comment

  schema "camps" do
    field :content, :string

    has_many :camp_child_relationships, CampChildRelationship, foreign_key: :parent_id
    has_many :children, through: [:camp_child_relationships, :child]

    has_one :camp_parent_relationship, CampChildRelationship, foreign_key: :child_id
    has_one :parent, through: [:camp_parent_relationship, :parent]

    has_many :camp_opponent_relationships, CampOpponentRelationship, foreign_key: :camp_id
    has_many :opponents, through: [:camp_opponent_relationships, :opponent]

    has_one :camp_data, CampData
    belongs_to :subject, Subject
    belongs_to :top_subject, Subject

    has_many :ratings, Rating

    field :status, Camp1.Ecto.AtomType
    field :type, Camp1.Ecto.AtomType

    timestamps()
  end

  @doc false
  def changeset(camp, attrs) do
    camp
    |> cast(attrs, [:type, :status])
    |> validate_required([:type, :status])
  end

  def create_changeset(camp, params) do
    camp
    |> changeset(params)
    |> cast(params, [:original_content, :subject_id, :top_subject_id])
    |> cast_assoc(:camp_child_relationships)
    |> cast_assoc(:camp_parent_relationship)
    |> cast_assoc(:camp_opponent_relationships)
    |> cast_assoc(:camp_data)
    |> validate_required([:original_content], [trim: true])
    |> put_current_content()
    |> add_camp_data()
  end

  def update_changset(camp, params) do
    camp
    |> changeset(params)
    |> cast(params, [:current_content, :subject_id, :top_subject_id])
    |> cast_assoc(:camp_opponent_relationships)
    |> validate_required([:current_content], [trim: true])
  end

  defp add_camp_data(changeset) do
    put_change(changeset, :camp_data, %{general_data: %{}})
  end

  defp put_current_content(changeset) do
    case fetch_change(changeset, :original_content) do
      {:ok, content} -> put_change(changeset, :current_content, content)
      :error -> changeset
    end
  end

  def calculate_and_update_camp_data(camp_id) do
    members =
      query_db_for_camp_member_count(camp_id)
      |> Repo.all
      |> List.first
    children =
      query_db_for_camp_child_count(camp_id)
      |> Repo.all
      |> List.first
    messages =
      query_db_for_camp_message_count(camp_id)
      |> Repo.all
      |> List.first
    posts =
      query_db_for_camp_post_count(camp_id)
      |> Repo.all
      |> List.first
    images =
      query_db_for_camp_image_count(camp_id)
      |> Repo.all
      |> List.first
    documents =
      query_db_for_camp_document_count(camp_id)
      |> Repo.all
      |> List.first
    opponents =
      query_db_for_camp_opponent_members(camp_id)
      |> Repo.all
      |> List.first
    top_opponents =
      query_db_for_camp_top_opponents(camp_id)
      |> Repo.all
    top_reasons =
      query_db_for_camp_top_reasons(camp_id)
      |> Repo.all
    attrs = %{
      child_count: children,
      member_count: members,
      opponent_count: opponents,
      top_opponents: top_opponents,
      top_reasons: top_reasons,
      message_count: messages,
      post_count: posts,
      document_count: documents,
      image_count: images,
    }
    {:ok, data} = Public.get_camp_data(camp_id)
      |> Public.update_camp_data(attrs)
    data
  end



  defp query_db_for_camp_message_count(camp_id) do
    from message in PublicMessage,
      where: message.camp_id == ^camp_id,
      select: count(message.id)
  end

  defp query_db_for_camp_post_count(camp_id) do
    from comment in Comment,
      where: comment.camp_id == ^camp_id,
      where: is_nil(comment.parent_id),
      where: is_nil(comment.image_id),
      where: is_nil(comment.document_id),
      select: count(comment.id)
  end

  defp query_db_for_camp_image_count(camp_id) do
    from comment in Comment,
      where: comment.camp_id == ^camp_id,
      where: is_nil(comment.parent_id),
      where: not is_nil(comment.image_id),
      where: is_nil(comment.document_id),
      select: count(comment.id)
  end

  defp query_db_for_camp_document_count(camp_id) do
    from comment in Comment,
      where: comment.camp_id == ^camp_id,
      where: is_nil(comment.parent_id),
      where: is_nil(comment.image_id),
      where: not is_nil(comment.document_id),
      select: count(comment.id)
  end

  defp query_db_for_camp_member_count(camp_id) do
    from rate in Rating,
      where: rate.camp_id == ^camp_id,
      where: rate.value in [4,5],
      select: count(rate.id)
  end

  defp query_db_for_camp_child_count(camp_id) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      select: count(rel.id)
  end

  defp query_db_for_camp_opponent_members(camp_id) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id == ^camp_id,
      join: rate in Rating,
      where: rate.camp_id == rel.opponent_id,
      where: rate.value in [4,5],
      select: count(rate.id)
  end

  defp query_db_for_camp_top_opponents(camp_id) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id == ^camp_id,
      join: data in CampData,
      where: data.id == rel.opponent_id,
      order_by: data.member_count,
      join: camp in __MODULE__,
      where: camp.id == rel.opponent_id,
      limit: 20,
      select: %{current_content: camp.current_content, id: camp.id, member_count: data.member_count}
  end

  defp query_db_for_camp_top_reasons(camp_id) do
    from rel in CampChildRelationship,
      where: rel.parent_id == ^camp_id,
      where: rel.type == :reason,
      join: data in CampData,
      where: data.id == rel.child_id,
      order_by: {:desc, data.member_count},
      join: camp in __MODULE__,
      where: camp.id == rel.child_id,
      limit: 20,
      select: %{current_content: camp.current_content, id: camp.id, member_count: data.member_count}
  end


end
