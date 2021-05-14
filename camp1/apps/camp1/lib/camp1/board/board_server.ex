defmodule Camp1.Board.BoardServer do
  alias Camp1.Board
  alias Camp1.Reputation
  import Ecto.Query, warn: false
  alias Camp1.CampServer

  def get_posts(camp_id, type, order_by, page, date) do
    process = get_board_process(camp_id)
    posts = GenServer.call(process, {:get_posts, type, order_by, page, date})
    case posts do
      nil ->
        posts = Board.get_posts(camp_id, type, order_by, page, date)
        GenServer.cast(process, {:put_posts, posts, type, order_by, page, date})
        posts
      posts ->
        posts
    end
  end

  def get_post(camp_id, comment_id) do
    process = get_board_process(camp_id)
    {:ok, post} = GenServer.call(process, {:get_comment, comment_id})
    case post do
      nil ->
        post = Board.get_comment_for_stash(comment_id)
        GenServer.cast(process, {:put_comment, post})
        post
      post ->
        post
    end
  end

  def get_comments(comment_id, camp_id, page) do
    process = get_board_process(camp_id)
    comments = GenServer.call(process, {:get_post_comments, comment_id, page})
    case comments do
      nil ->
        comments = Board.get_comments(comment_id, page)
        GenServer.cast(process, {:put_post_comments, comment_id, comments, page})
        comments
      comments ->
        comments
    end
  end

  def put_new_vote_to_server(camp_id, comment_id, 1, _opts = %{updating?: true}) do
    process = get_board_process(camp_id)
    GenServer.cast(process, {:new_vote, {comment_id, -1}})
  end
  def put_new_vote_to_server(camp_id, comment_id, -1, _opts = %{updating?: true}) do
    process = get_board_process(camp_id)
    GenServer.cast(process, {:new_vote, {comment_id, 1}})
  end
  def put_new_vote_to_server(camp_id, comment_id, 1, _opts = %{flip_vote?: true}) do
    process = get_board_process(camp_id)
    GenServer.cast(process, {:new_vote, {comment_id, 2}})
  end
  def put_new_vote_to_server(camp_id, comment_id, -1, _opts = %{flip_vote?: true}) do
    process = get_board_process(camp_id)
    GenServer.cast(process, {:new_vote, {comment_id, -2}})
  end
  def put_new_vote_to_server(camp_id, comment_id, value, _opts) do
    process = get_board_process(camp_id)
    GenServer.cast(process, {:new_vote, {comment_id, value}})
  end

  def add_new_comment_to_server(comment) do
    process = get_board_process(comment.camp_id)
    GenServer.cast(process, {:new_comment, format_comment_for_server(comment)})
  end

  def add_new_comment_comment_to_server(comment) do
    process = get_board_process(comment.camp_id)
    GenServer.cast(process, {:new_comment_comment, format_comment_for_server(comment)})
  end

  defp format_comment_for_server(comment) do
    %{
      id: comment.id,
      points: 1,
      content: comment.content,
      parent_id: comment.parent_id,
      user_handle: Reputation.get_handle(comment.user_id, comment.camp_id),
      comment_count: 0,
      inserted_at: comment.inserted_at,
      image_id: comment.image_id,
      document_id: comment.document_id
    }
  end




  defp get_board_process(camp_id) do
    process = Process.whereis(:"CampBoardStash-#{camp_id}")
    case process do
      nil ->
        CampServer.start_camp_supervisor(camp_id)
        get_board_process(camp_id)
      process ->
        process
    end
  end

  # defp get_extra_data(comment_id) do
  #   q = from c in Comment,
  #     where: c.id == ^comment_id,
  #     join: v in Vote,
  #     where: v.comment_id == c.id,
  #     join: h in Handle,
  #     where: h.camp_id == c.camp_id,
  #     where: h.user_id == c.user_id,
  #     group_by: [c.id, h.value],
  #     select: %{points: sum(v.value), user_handle: h.value}
  #   Repo.all(q)
  #   |> List.first
  # end
end
