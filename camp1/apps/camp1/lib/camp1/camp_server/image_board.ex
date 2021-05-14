defmodule Camp1.CampServer.ImageBoard do
  use GenServer
  alias Camp1.Board
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @update 60 * 60 * 1000

  # updates on the minute to push posts from recent posts to days posts
  # stashes days posts and weeks post with expiry date (timestamp inserted in map when put in stash)

  def start_link(%{name: name, camp_id: camp_id}) do
    GenServer.start_link(
      __MODULE__,
      %{
        camp_id: camp_id,
        all_time_top_posts: nil,
        recent_posts: nil,
        comments: %{},
        top_day_posts: %{},
        top_week_posts: %{},
        top_comments: %{},
        expiries: %{ days_posts: %{}, weeks_posts: %{}, comments_posts: %{}}
      },
      name: name,
      hibernate_after: @hibernate)
  end

  def init(stash) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@update, :update_stash)
    {:ok, stash}
  end

  def handle_call({:get_recent_posts, page}, _from, stash = %{recent_posts: recent_posts, comments: comments}) do
    :timer.send_after(@timeout, :job_timeout)
    case recent_posts do
      nil ->
        {:reply, {:ok, recent_posts}, stash}
      recent_posts ->
        recent_posts =
          recent_posts
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(comments[&1]))
        {:reply, {:ok, recent_posts}, stash}
    end
  end

  def handle_call({:get_days_top_posts, days_ago, page}, _from, stash = %{top_day_posts: top_day_posts, comments: comments}) do
    :timer.send_after(@timeout, :job_timeout)
    posts =  Map.get(top_day_posts, days_ago)
    case posts do
      nil ->
        {:reply, {:ok, posts}, stash}
      posts ->
        posts =
          posts
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(comments[&1]))
        {:reply, {:ok, posts}, stash}
    end
  end

  def handle_call({:get_weeks_top_posts, weeks_ago, page}, _from, stash = %{top_week_posts: top_week_posts, comments: comments}) do
    posts =  Map.get(top_week_posts, weeks_ago)
    case posts do
      nil ->
        {:reply, {:ok, posts}, stash}
      posts ->
        posts =
          posts
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(comments[&1]))
        {:reply, {:ok, posts}, stash}
    end
  end

  def handle_call({:get_all_time_top_posts, page}, _from, stash = %{all_time_top_posts: all_time_top_posts, comments: comments}) do
    case all_time_top_posts do
      nil ->
        {:reply, {:ok, all_time_top_posts}, stash}
      all_time_top_posts ->
        posts =
          all_time_top_posts
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(comments[&1]))
        {:reply, {:ok, posts}, stash}
    end
  end

  def handle_call({:get_top_comments, comment_id, page}, _from, stash = %{top_comments: top_comments, comments: comments}) do
    comment_id = make_sure_int comment_id
    top_comments =  Map.get(top_comments, comment_id)
    case top_comments do
      nil ->
        {:reply, {:ok, top_comments}, stash}
      top_comments ->
        top_comments =
          top_comments
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(comments[&1]))
        {:reply, {:ok, top_comments}, stash}
    end
  end


  def handle_call({:get_comment, comment_id}, _from, stash = %{comments: comments}) do
    comment_id = make_sure_int comment_id
    comment =  Map.get(comments, comment_id)
    {:reply, {:ok, comment}, stash}
  end

  def handle_cast({:put_comment, comment}, stash = %{comments: comments}) do
    comments = Map.put(comments, comment.id, comment)
    {:noreply, Map.put(stash, :comments, comments)}
  end

  def handle_cast({:put_all_time_top_posts, top_posts}, stash = %{comments: comments, expiries: expiries}) do
    date = Timex.shift(DateTime.utc_now, days: 1)
    expiries = Map.put(expiries, :all_time_top_posts, date)
    top_post_ids = Enum.map(top_posts, &(&1.id))
    comments = Enum.reduce(top_posts, comments, fn comment, comment_map ->
      Map.put_new(comment_map, comment.id, comment)
    end)
    stash =
      stash
      |> Map.put(:all_time_top_posts, top_post_ids)
      |> Map.put(:expiries, expiries)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end

  def handle_cast({:put_recent_posts, top_posts}, stash = %{comments: comments}) do
    top_post_ids =
      Enum.map(top_posts, &(&1.id))
      |> Enum.take(200)
    comments = Enum.reduce(top_posts, comments, fn comment, comment_map ->
      Map.put_new(comment_map, comment.id, comment)
    end)
    stash =
      stash
      |> Map.put(:recent_posts, top_post_ids)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end

  def handle_cast({:put_days_top_posts, days_ago, top_posts}, stash = %{top_day_posts: top_day_posts, comments: comments, expiries: expiries =  %{ days_posts: expiries_days}}) do
    date = Timex.shift(DateTime.utc_now, days: 1)
    expiries_days = Map.put(expiries_days, days_ago, date)
    expiries = Map.put(expiries, :days_posts, expiries_days)

    top_post_ids = Enum.map(top_posts, &(&1.id))
    top_day_posts = Map.put(top_day_posts, days_ago, top_post_ids)
    comments = Enum.reduce(top_posts, comments, fn comment, comment_map ->
      Map.put_new(comment_map, comment.id, comment)
    end)
    stash =
      stash
      |> Map.put(:top_day_posts, top_day_posts)
      |> Map.put(:expiries, expiries)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end

  def handle_cast({:put_weeks_top_posts, weeks_ago, top_posts}, stash = %{top_week_posts: top_week_posts, comments: comments, expiries: expiries =  %{ weeks_posts: expiries_weeks}}) do
    date = Timex.shift(DateTime.utc_now, days: 1)
    expiries_weeks = Map.put(expiries_weeks, weeks_ago, date)
    expiries = Map.put(expiries, :weeks_posts, expiries_weeks)

    top_post_ids = Enum.map(top_posts, &(&1.id))
    top_week_posts = Map.put(top_week_posts, weeks_ago, top_post_ids)
    comments = Enum.reduce(top_posts, comments, fn comment, comment_map ->
      Map.put_new(comment_map, comment.id, comment)
    end)
    stash =
      stash
      |> Map.put(:top_week_posts, top_week_posts)
      |> Map.put(:expiries, expiries)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end


  def handle_cast({:put_top_comments, comment_id, comment_top_comments}, stash = %{comments: comments, top_comments: top_comments, expiries: expiries =  %{ comments_posts: expiries_comments}}) do
    comment_id = make_sure_int comment_id
    date = Timex.shift(DateTime.utc_now, days: 1)
    expiries_comments = Map.put(expiries_comments, comment_id, date)
    expiries = Map.put(expiries, :comments_posts, expiries_comments)

    top_comment_ids = Enum.map(comment_top_comments, &(&1.id))
    top_comments = Map.put(top_comments, comment_id, top_comment_ids)

    comments = Enum.reduce(comment_top_comments, comments, fn comment, comment_map ->
      Map.put_new(comment_map, comment.id, comment)
    end)
    stash =
      stash
      |> Map.put(:expiries, expiries)
      |> Map.put(:top_comments, top_comments)
      |> Map.put(:comments, comments)
    # send(self(), {:update_comment_count, comment_id, length(comment_top_comments)})
    :timer.send_after(100, {:update_comment_count, comment_id, length(comment_top_comments)})
    {:noreply, stash}
  end

  def handle_cast({:new_vote, {comment_id, value}}, stash = %{comments: comments}) do
    comment =
      Map.get(comments, comment_id)
      |> Map.update!(:points, &(&1 + value))
    comments = Map.put(comments, comment_id, comment)
    stash =
      stash
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end

  def handle_cast({:new_comment, comment = %{id: id}}, stash = %{recent_posts: recent_posts, comments: comments}) do
    id = make_sure_int id
    comments = Map.put(comments, id, comment)
    recent_posts = [id | recent_posts]
    stash =
      stash
      |> Map.put(:recent_posts, recent_posts)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end

  def handle_cast({:new_comment_comment, comment = %{id: id, parent_id: parent_id}}, stash = %{top_comments: top_comments, comments: comments}) do
    parent_id = make_sure_int parent_id
    id = make_sure_int id
    parent_comment =
      Map.get(comments, parent_id)
    parent_comment = add_1_to_comment_count(parent_comment, parent_comment.comment_count)
    comments =
      comments
      |> Map.put(id, comment)
      |> Map.put(parent_id, parent_comment)

    comment_comments = [id | Map.get(top_comments, parent_id, [])]
    comment_comments = sort_comments_by_votes(Map.take(comments, comment_comments))
    top_comments = Map.put(top_comments, parent_id, comment_comments)
    stash =
      stash
      |> Map.put(:top_comments, top_comments)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end

  def handle_info({:update_comment_count, comment_id, comment_count}, stash = %{comments: comments}) do
    comment_id = make_sure_int(comment_id)
    comment =
      Map.get(comments, comment_id)
      |> Map.put(:comment_count, comment_count)

    comments = Map.put(comments, comment_id, comment)


    {:noreply, Map.put(stash, :comments, comments)}
  end

  def handle_info(:update_stash, stash) do
    stash =
      delete_expired_comments(stash)
      |> delete_expired_days()
      |> delete_expired_weeks()
      |> update_all_time_to_nil()
      |> update_todays_posts_to_nil()
      |> update_database_with_comment_counts()
      |> delete_unused_comments()
      |> sort_all_comments_lists_by_votes()

    :timer.send_after(@update, :update_stash)
    {:noreply, stash}
  end


  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end

  defp delete_expired_comments(stash = %{top_comments: top_comments, expiries: expiries = %{comments_posts: comments_posts}}) do
    map_to_delete = :maps.filter(fn _, exp -> DateTime.compare(exp, DateTime.utc_now) == :lt end, comments_posts)
    top_comments = Map.drop(top_comments, Map.keys(map_to_delete))
    comments_posts = Map.drop(comments_posts, Map.keys(map_to_delete))
    expiries = Map.put(expiries, :comments_posts, comments_posts)
    Map.put(stash, :top_comments, top_comments)
    |> Map.put(:expiries, expiries)
  end

  defp delete_expired_weeks(stash = %{top_week_posts: top_week_posts, expiries: expiries = %{weeks_posts: weeks_posts}}) do
    map_to_delete = :maps.filter(fn _, exp -> DateTime.compare(exp, DateTime.utc_now) == :lt end, weeks_posts)
    top_week_posts = Map.drop(top_week_posts, Map.keys(map_to_delete))
    weeks_posts = Map.drop(weeks_posts, Map.keys(map_to_delete))
    expiries = Map.put(expiries, :weeks_posts, weeks_posts)
    Map.put(stash, :top_week_posts, top_week_posts)
    |> Map.put(:expiries, expiries)
  end

  defp delete_expired_days(stash = %{top_day_posts: top_day_posts, expiries: expiries = %{days_posts: days_posts}}) do
    map_to_delete = :maps.filter(fn _, exp -> DateTime.compare(exp, DateTime.utc_now) == :lt end, days_posts)
    top_day_posts = Map.drop(top_day_posts, Map.keys(map_to_delete))
    days_posts = Map.drop(days_posts, Map.keys(map_to_delete))
    expiries = Map.put(expiries, :days_posts, days_posts)
    Map.put(stash, :top_day_posts, top_day_posts)
    |> Map.put(:expiries, expiries)
  end

  defp update_all_time_to_nil(stash = %{expiries: expiries}) do
    all_time_expiry = Map.get(expiries, :all_time_top_posts)
    case all_time_expiry do
      nil ->
        stash
      date ->
        cond do
          date < DateTime.utc_now ->
            Map.put(stash, :all_time_top_posts, nil)
          true ->
            stash
        end
    end
  end

  defp update_todays_posts_to_nil(stash = %{top_day_posts: top_day_posts}) do
    date = Timex.to_date(Timex.now)
    top_day_posts = Map.put(top_day_posts, date, nil)
    Map.put(stash, :top_day_posts, top_day_posts)
  end

  defp delete_unused_comments(stash = %{comments: comments}) do
    all_time_top_posts = if is_nil(stash.all_time_top_posts), do: [], else: stash.all_time_top_posts
    recent_posts = if is_nil(stash.recent_posts), do: [], else: stash.recent_posts
    comment_ids =
      all_time_top_posts
      |> List.flatten(Map.values(stash.top_week_posts))
      |> List.flatten(Map.values(stash.top_day_posts))
      |> List.flatten(Map.values(stash.top_comments))
      |> List.flatten(recent_posts)
      |> Enum.uniq
    comment_ids = Map.keys(comments) -- comment_ids
    comments = Map.drop(comments, comment_ids)
    Map.put(stash, :comments, comments)
  end

  defp sort_all_comments_lists_by_votes(stash = %{comments: comments}) do
    stash
    |> Map.put(:top_week_posts, sort_all_lists(stash.top_week_posts, comments))
    |> Map.put(:top_week_posts, sort_all_lists(stash.top_day_posts, comments))
    |> Map.put(:top_week_posts, sort_all_lists(stash.top_comments, comments))
    |> Map.put(:all_time_top_posts, sort_list(stash.all_time_top_posts, comments))
  end

  defp sort_list(nil, _comments) do
    nil
  end
  defp sort_list(list, comments) do
    Enum.sort_by(list, fn id -> -comments[id].points end)
  end

  defp sort_all_lists(map_of_lists, comments) do
    keys = Map.keys(map_of_lists)
    Enum.reduce(keys, %{}, fn key, map ->
      Map.put(map, key, sort_list(map_of_lists[key], comments))
    end)
  end

  defp update_database_with_comment_counts(stash = %{comments: comments}) do
    Enum.each(comments, fn {id, comment} ->
      Board.get_comment(id)
      |> Board.update_comment(%{comment_count: comment.comment_count})
    end)
    stash
  end

  defp sort_comments_by_votes(comments) do
    Enum.sort_by(comments, fn _ -> &(&1.points) end) \
    |> Enum.map(fn {_id, comment} -> comment.id end)
  end

  defp make_sure_int(id) when is_integer(id), do: id
  defp make_sure_int(id) when is_binary(id), do: String.to_integer(id)

  defp add_1_to_comment_count(comment, nil) do
    Map.put(comment, :comment_count, 1)
  end
  defp add_1_to_comment_count(comment, count) do
    Map.put(comment, :comment_count, count + 1)
  end
end
