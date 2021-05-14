defmodule SeedComments do
  # alias Camp1.Repo
  import Ecto.Query, warn: false
  alias Camp1.{Board, Public, Reactions}


  def add_base_comments_to_camps() do
    Public.list_camps
    |> Enum.each(fn camp ->
      user_ids = Public.get_camp_member_ids(camp.id)
      if user_ids != [] do
        1..3
        |> Enum.each(fn _i ->
          create_base_comment(camp.id, user_ids)
        end)
      end
    end)
  end

  def add_comments_to_camp(camp_id, n) do
    camp = Public.get_camp(camp_id)
    user_ids = Public.get_camp_member_ids(camp.id)
    0..100
    |> Enum.each(fn i ->
      1..n
      |> Enum.each(fn _i ->
        IO.puts i
        create_base_comment_days_ago(camp.id, user_ids, i)
      end)
    end)
  end

  def add_comments_to_comments() do
    Board.list_comments
    |> Enum.each(fn comment ->
      user_ids = Public.get_camp_member_ids(comment.camp_id)
      create_comment_comment(comment, user_ids)
    end)
  end

  def add_comments_to_comments(comments) do
    comments
    |> Enum.each(fn comment ->
      user_ids = Public.get_camp_member_ids(comment.camp_id)
      create_comment_comment(comment, user_ids)
    end)
  end

  def seed_votes(n) do
    Board.list_comments
    |> Enum.each(fn comment ->
      user_ids = Public.get_camp_member_ids(comment.camp_id)
      create_n_votes(n, comment, user_ids)
    end)
  end

  def seed_votes(comments, n) do
    comments
    |> Enum.each(fn comment ->
      user_ids = Public.get_camp_member_ids(comment.camp_id)
      create_n_votes(n, comment, user_ids)
    end)
  end

  def create_n_votes(n, comment, user_ids) do
    1..n
    |> Enum.each(fn _i ->
      value = Enum.random([-1, 1, 1, 1])
      user_id = Enum.random(user_ids)
      Reactions.create_vote(%{
        comment_id: comment.id,
        user_id: user_id,
        value: value
        })
    end)
  end

  def create_base_comment(camp_id, user_ids) do
    user_id = Enum.random(user_ids)
    Board.create_comment(%{
      user_id: user_id,
      camp_id: camp_id,
      parent_id: nil,
      content: FakerElixir.Lorem.sentence
      })
  end

  def create_base_comment_days_ago(camp_id, user_ids, i) do
    user_id = Enum.random(user_ids)
    inserted_at = Timex.shift(DateTime.utc_now, days: -i)
    Board.create_comment(%{
      user_id: user_id,
      camp_id: camp_id,
      parent_id: nil,
      content: FakerElixir.Lorem.sentence,
      inserted_at: inserted_at
      })
  end

  def create_comment_comment(comment, user_ids) do
    user_id = Enum.random(user_ids)
    Board.create_comment(%{
      user_id: user_id,
      camp_id: comment.camp_id,
      parent_id: comment.id,
      content: FakerElixir.Lorem.sentence
      })
  end


end
