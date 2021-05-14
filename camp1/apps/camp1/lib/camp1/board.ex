defmodule Camp1.Board do
  alias Camp1.Board.{Comment, BoardServer}
  alias Camp1.Reactions.Vote
  alias Camp1.Reputation.Handle
  alias Ecto.Multi
  import Ecto.Query, warn: false
  alias Camp1.{Repo, Public}
  alias Camp1.Public.{ImageRelationship, DocumentRelationship}

  defdelegate add_new_comment_to_server(comment), to: BoardServer
  defdelegate add_new_comment_comment_to_server(comment), to: BoardServer
  defdelegate put_new_vote_to_server(camp_id, comment_id, value, opts), to: BoardServer

  # GETTERS
  def get_posts(camp_id, type, order_by, page, date)
  def get_posts(camp_id, type, :recent, page, _date) do
    query_recent_posts_of_type(camp_id, type, page)
    |> Repo.all
  end
  def get_posts(camp_id, type, :top_all_time, page, _date) do
    query_top_posts_of_type(camp_id, type, page)
    |> Repo.all
  end
  def get_posts(camp_id, type, :controversial_all_time, page, _date) do
    query_controversial_posts_of_type(camp_id, type, page)
    |> Repo.all
  end
  def get_posts(camp_id, type, :top_day, page, date) do
    query_top_posts_of_type(camp_id, type, page, date, :day)
    |> Repo.all
  end
  def get_posts(camp_id, type, :top_week, page, date) do
    query_top_posts_of_type(camp_id, type, page, date, :week)
    |> Repo.all
  end
  def get_posts(camp_id, type, :controversial_day, page, date) do
    query_controversial_posts_of_type(camp_id, type, page, date, :day)
    |> Repo.all
  end
  def get_posts(camp_id, type, :controversial_week, page, date) do
    query_controversial_posts_of_type(camp_id, type, page, date, :week)
    |> Repo.all
  end

  def get_comment(id) do
    Comment
    |> Repo.get(id)
  end
  def get_comments(comment_id, page) do
    query_comments(comment_id, page)
    |> Repo.all
  end
  def get_comment_for_stash(id) do
    query_comment(id)
    |> Repo.all
    |> List.first
  end

  def list_comments() do
    Repo.all(Comment)
  end


  # CREATORS
  def create_comment(attrs) do
    Multi.new()
    |> Multi.insert(:comment, Comment.changeset(%Comment{}, attrs))
    |> Multi.merge(fn %{comment: comment} ->
      Multi.new()
      |> Multi.insert(:vote, Vote.changeset(
        %Vote{},
        %{
          comment_id: comment.id,
          user_id: attrs.user_id,
          value: 1
        }
      ))
    end)
    |> Repo.transaction()
  end
  def create_comment_with_image(attrs, upload) do
    Multi.new()
    |> Multi.insert(:comment, Comment.changeset(%Comment{}, attrs))
    |> Multi.merge(fn %{comment: comment} ->
      Multi.new()
      |> Multi.insert(:vote, Vote.changeset(
        %Vote{},
        %{
          comment_id: comment.id,
          user_id: attrs.user_id,
          value: 1
        }
      ))
      |> Multi.run(:image, Public, :create_image_upload_from_plug_upload, [upload])
      |> Multi.merge(fn %{image: image} ->
        Multi.new()
        |> Multi.insert(:image_relationship, ImageRelationship.changeset(
          %ImageRelationship{},
          %{
            other_id: comment.id,
            image_id: image.id,
            type: "comment"
          }
        ))
        |> Multi.update(:updated_comment, Comment.changeset(comment, %{image_id: image.id}))
      end)
    end)
    |> Repo.transaction()
  end

  def create_comment_with_document(attrs, upload) do
    Multi.new()
    |> Multi.insert(:comment, Comment.changeset(%Comment{}, attrs))
    |> Multi.merge(fn %{comment: comment} ->
      Multi.new()
      |> Multi.insert(:vote, Vote.changeset(
        %Vote{},
        %{
          comment_id: comment.id,
          user_id: attrs.user_id,
          value: 1
        }
      ))
      |> Multi.run(:document, Public, :create_document_upload_from_plug_upload, [upload])
      |> Multi.merge(fn %{document: document} ->
        Multi.new()
        |> Multi.insert(:document_relationship, DocumentRelationship.changeset(
          %DocumentRelationship{},
          %{
            other_id: comment.id,
            document_id: document.id,
            type: "comment"
          }
        ))
        |> Multi.update(:updated_comment, Comment.changeset(comment, %{document_id: document.id}))
      end)
    end)
    |> Repo.transaction()
  end

  # UPDATERS
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end



  # PRIVATE QUERIES

  defp query_comment(comment_id) do
    from c in Comment,
      where: c.id == ^comment_id,
      left_join: dv in Vote,
      on: (dv.comment_id == c.id) and (dv.value == -1),
      left_join: uv in Vote,
      on: (uv.comment_id == c.id) and (uv.value == 1),
      left_join: children in assoc(c, :children),
      join: h in Handle,
      where: h.camp_id == c.camp_id,
      where: h.user_id == c.user_id,
      group_by: [c.id, h.value],
      select: %{
        id: c.id,
        points: (count(uv.id, :distinct) - count(dv.id, :distinct)),
        content: c.content,
        user_handle: h.value,
        inserted_at: c.inserted_at,
        comment_count: count(children.id, :distinct),
        parent_id: c.parent_id,
        image_id: c.image_id,
        document_it: c.document_id
      }
  end

  defp query_comments(comment_id, page) do
    from c in Comment,
      where: c.parent_id == ^comment_id,
      left_join: dv in Vote,
      on: (dv.comment_id == c.id) and (dv.value == -1),
      left_join: uv in Vote,
      on: (uv.comment_id == c.id) and (uv.value == 1),
      left_join: children in assoc(c, :children),
      join: h in Handle,
      where: h.camp_id == c.camp_id,
      where: h.user_id == c.user_id,
      group_by: [c.id, h.value],
      order_by: {:desc, (count(uv.id, :distinct) - count(dv.id, :distinct))},
      offset: (^page * 20),
      limit: 20,
      select: %{
        id: c.id,
        points: (count(uv.id, :distinct) - count(dv.id, :distinct)),
        content: c.content,
        user_handle: h.value,
        inserted_at: c.inserted_at,
        comment_count: count(children.id, :distinct),
        parent_id: c.parent_id,
        image_id: c.image_id,
        document_it: c.document_id
      }
  end


  defp query_controversial_posts_of_type(camp_id, :posts, page) do
    from c in query_controversial_posts(camp_id, page),
      where: is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_controversial_posts_of_type(camp_id, :images, page) do
    from c in query_controversial_posts(camp_id, page),
      where: not is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_controversial_posts_of_type(camp_id, :documents, page) do
    from c in query_controversial_posts(camp_id, page),
      where: is_nil(c.image_id),
      where: not is_nil(c.document_id)
  end
  defp query_top_posts_of_type(camp_id, :posts, page) do
    from c in query_top_posts(camp_id, page),
      where: is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_top_posts_of_type(camp_id, :images, page) do
    from c in query_top_posts(camp_id, page),
      where: not is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_top_posts_of_type(camp_id, :documents, page) do
    from c in query_top_posts(camp_id, page),
      where: is_nil(c.image_id),
      where: not is_nil(c.document_id)
  end
  defp query_top_posts_of_type(camp_id, :posts, page, date, range) do
    from c in query_top_posts_in_range(camp_id, page, date, range),
      where: is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_top_posts_of_type(camp_id, :images, page, date, range) do
    from c in query_top_posts_in_range(camp_id, page, date, range),
      where: not is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_top_posts_of_type(camp_id, :documents, page, date, range) do
    from c in query_top_posts_in_range(camp_id, page, date, range),
      where: is_nil(c.image_id),
      where: not is_nil(c.document_id)
  end

  defp query_top_posts_in_range(camp_id, page, date, :day) do
    start_time = start_of_day(date)
    end_time = end_of_day(date)
    from c in query_top_posts(camp_id, page),
      where: c.inserted_at > ^start_time,
      where: c.inserted_at < ^end_time
  end
  defp query_top_posts_in_range(camp_id, page, date, :week) do
    start_time = start_of_week(date)
    end_time = end_of_week(date)
    from c in query_top_posts(camp_id, page),
      where: c.inserted_at > ^start_time,
      where: c.inserted_at < ^end_time
  end

  defp query_controversial_posts_of_type(camp_id, :posts, page, date, range) do
    from c in query_controversial_posts_in_range(camp_id, page, date, range),
      where: is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_controversial_posts_of_type(camp_id, :images, page, date, range) do
    from c in query_controversial_posts_in_range(camp_id, page, date, range),
      where: not is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_controversial_posts_of_type(camp_id, :documents, page, date, range) do
    from c in query_controversial_posts_in_range(camp_id, page, date, range),
      where: is_nil(c.image_id),
      where: not is_nil(c.document_id)
  end
  defp query_controversial_posts_in_range(camp_id, page, date, :week) do
    start_time = start_of_week(date)
    end_time = end_of_week(date)
    from c in query_controversial_posts(camp_id, page),
      where: c.inserted_at > ^start_time,
      where: c.inserted_at < ^end_time
  end
  defp query_controversial_posts_in_range(camp_id, page, date, :day) do
    start_time = start_of_day(date)
    end_time = end_of_day(date)
    from c in query_controversial_posts(camp_id, page),
      where: c.inserted_at > ^start_time,
      where: c.inserted_at < ^end_time
  end

  defp query_recent_posts_of_type(camp_id, :posts, page) do
    from c in query_recent_posts(camp_id, page),
      where: is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_recent_posts_of_type(camp_id, :images, page) do
    from c in query_recent_posts(camp_id, page),
      where: not is_nil(c.image_id),
      where: is_nil(c.document_id)
  end
  defp query_recent_posts_of_type(camp_id, :documents, page) do
    from c in query_recent_posts(camp_id, page),
      where: is_nil(c.image_id),
      where: not is_nil(c.document_id)
  end
  defp query_recent_posts(camp_id, page) do
    from c in query_posts(camp_id, page),
      order_by: {:desc, c.inserted_at}
  end

  defp query_top_posts(camp_id, page) do
    from c in Comment,
      where: c.camp_id == ^camp_id,
      where: is_nil(c.parent_id),
      left_join: dv in Vote,
      on: (dv.comment_id == c.id) and (dv.value == -1),
      left_join: uv in Vote,
      on: (uv.comment_id == c.id) and (uv.value == 1),
      left_join: children in assoc(c, :children),
      left_join: h in Handle,
      where: h.camp_id == ^camp_id,
      where: h.user_id == c.user_id,
      group_by: [c.id, h.value],
      order_by: {:desc, (count(uv.id, :distinct) - count(dv.id, :distinct))},
      offset: (^page * 20),
      limit: 20,
      select: %{
        id: c.id,
        points: (count(uv.id, :distinct) - count(dv.id, :distinct)),
        content: c.content,
        user_handle: h.value,
        inserted_at: c.inserted_at,
        comment_count: count(children.id, :distinct),
        parent_id: c.parent_id,
        image_id: c.image_id,
        document_id: c.document_id
      }
  end

  defp query_controversial_posts(camp_id, page) do
    from c in Comment,
      where: c.camp_id == ^camp_id,
      where: is_nil(c.parent_id),
      left_join: dv in Vote,
      on: (dv.comment_id == c.id) and (dv.value == -1),
      left_join: uv in Vote,
      on: (uv.comment_id == c.id) and (uv.value == 1),
      left_join: children in assoc(c, :children),
      left_join: h in Handle,
      where: h.camp_id == ^camp_id,
      where: h.user_id == c.user_id,
      group_by: [c.id, h.value],
      order_by: (count(uv.id, :distinct) - count(dv.id, :distinct)),
      offset: (^page * 20),
      limit: 20,
      select: %{
        id: c.id,
        points: (count(uv.id, :distinct) - count(dv.id, :distinct)),
        content: c.content,
        user_handle: h.value,
        inserted_at: c.inserted_at,
        comment_count: count(children.id, :distinct),
        parent_id: c.parent_id,
        image_id: c.image_id,
        document_id: c.document_id
      }
  end

  defp query_posts(camp_id, page) do
    from c in Comment,
      where: c.camp_id == ^camp_id,
      where: is_nil(c.parent_id),
      left_join: dv in Vote,
      on: (dv.comment_id == c.id) and (dv.value == -1),
      left_join: uv in Vote,
      on: (uv.comment_id == c.id) and (uv.value == 1),
      left_join: children in assoc(c, :children),
      join: h in Handle,
      where: h.camp_id == ^camp_id,
      where: h.user_id == c.user_id,
      group_by: [c.id, h.id],
      offset: (^page * 20),
      limit: 20,
      select: %{
        id: c.id,
        points: (count(uv.id, :distinct) - count(dv.id, :distinct)),
        content: c.content,
        user_handle: h.value,
        inserted_at: c.inserted_at,
        comment_count: count(children.id, :distinct),
        parent_id: c.parent_id,
        image_id: c.image_id,
        document_id: c.document_id
      }
  end

  # HELPERS
  def date_string_to_date(date) do
    date =
      date
      |> String.split("-")
      |> Enum.map(&(String.to_integer &1))
    {:ok, date} = Date.new(Enum.at(date, 0), Enum.at(date, 1), Enum.at(date, 2))
    date
  end
  defp start_of_day(date) do
    date_string_to_date(date)
    |> Timex.to_datetime
    |> Timex.beginning_of_day
    |> Timex.shift(hours: 9)
  end

  defp start_of_week(date) do
    date_string_to_date(date)
    |> Timex.to_datetime
    |> Timex.beginning_of_week
    |> Timex.shift(hours: 9)
  end

  defp end_of_day(date) do
    date_string_to_date(date)
    |> Timex.to_datetime
    |> Timex.end_of_day
    |> Timex.shift(hours: 9)
  end

  defp end_of_week(date) do
    date_string_to_date(date)
    |> Timex.to_datetime
    |> Timex.end_of_week
    |> Timex.shift(hours: 9)
  end
end
