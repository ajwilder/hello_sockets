defmodule Camp1.CampServer.BoardStash do
  use GenServer
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @update 60 * 60 * 1000
  @hours_to_expire_comments -1

  # updates on the minute to push posts from recent posts to days posts
  # stashes days posts and weeks post with expiry date (timestamp inserted in map when put in stash)

  def start_link(%{name: name, camp_id: camp_id}) do
    GenServer.start_link(
      __MODULE__,
      %{
        camp_id: camp_id,
        top_all_time: %{
          posts: [],
          images: [],
          documents: []
          },
        controversial_all_time: %{
          posts: [],
          images: [],
          documents: []
          },
        recent: %{
          posts: [],
          images: [],
          documents: []
          },
        comments: %{},
        controversial_day: %{
          posts: %{},
          images: %{},
          documents: %{}
        },
        controversial_week: %{
          posts: %{},
          images: %{},
          documents: %{}
        },
        top_day: %{
          posts: %{},
          images: %{},
          documents: %{}
        },
        top_week: %{
          posts: %{},
          images: %{},
          documents: %{}
        },
        post_comments: %{},
        expires: %{
          top_day: %{
            posts: %{},
            images: %{},
            documents: %{}
          },
          top_week: %{
            posts: %{},
            images: %{},
            documents: %{}
          },
          controversial_day: %{
            posts: %{},
            images: %{},
            documents: %{}
          },
          controversial_week: %{
            posts: %{},
            images: %{},
            documents: %{}
          },
          post_comments: %{}
        },
      },
      name: name,
      hibernate_after: @hibernate)
  end

  def init(stash) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@update, :update_stash)
    {:ok, stash}
  end


  # POST GETTERS
  # def handle_call({:get_posts, type, order_by, page, date}, from, stash)
  def handle_call({:get_posts, type, :recent, page, _date}, _from, stash = %{recent: recent_posts, comments: comments}) do
    posts = Map.get(recent_posts, type)
    ids = Enum.at(posts, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_posts, type, :top_all_time, page, _date}, _from, stash = %{top_all_time: all_time_posts, comments: comments}) do
    posts = Map.get(all_time_posts, type)
    ids = Enum.at(posts, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_posts, type, :controversial_all_time, page, _date}, _from, stash = %{controversial_all_time: all_time_posts, comments: comments}) do
    posts = Map.get(all_time_posts, type)
    ids = Enum.at(posts, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_posts, type, :top_day, page, date}, _from, stash = %{top_day: top_day, comments: comments, expires: expires = %{top_day: top_day_expires}}) do
    day_posts = Map.get(top_day, type)
    ids = Map.get(day_posts, date, [])
    ids = Enum.at(ids, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        type_expires =
          Map.get(top_day_expires, type)
          |> Map.put(date, DateTime.utc_now)
        top_day_expires = Map.put(top_day_expires, type, type_expires)
        expires = Map.put(expires, :top_day, top_day_expires)
        stash =
          Map.put(stash, :expires, expires)
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_posts, type, :top_week, page, date}, _from, stash = %{top_week: top_week, comments: comments, expires: expires = %{top_week: top_week_expires}}) do
    week_posts = Map.get(top_week, type)
    ids = Map.get(week_posts, date, [])
    ids = Enum.at(ids, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        type_expires =
          Map.get(top_week_expires, type)
          |> Map.put(date, DateTime.utc_now)
        top_week_expires = Map.put(top_week_expires, type, type_expires)
        expires = Map.put(expires, :top_week, top_week_expires)
        stash =
          Map.put(stash, :expires, expires)
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_posts, type, :controversial_day, page, date}, _from, stash = %{controversial_day: controversial_day, comments: comments, expires: expires = %{controversial_day: controversial_day_expires}}) do
    day_post = Map.get(controversial_day, type)
    ids = Map.get(day_post, date, [])
    ids = Enum.at(ids, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        type_expires =
          Map.get(controversial_day_expires, type)
          |> Map.put(date, DateTime.utc_now)
        controversial_day_expires = Map.put(controversial_day_expires, type, type_expires)
        expires = Map.put(expires, :controversial_day, controversial_day_expires)
        stash =
          Map.put(stash, :expires, expires)
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_posts, type, :controversial_week, page, date}, _from, stash = %{controversial_week: controversial_week, comments: comments, expires: expires = %{controversial_week: controversial_week_expires}}) do
    week_posts = Map.get(controversial_week, type)
    ids = Map.get(week_posts, date, [])
    ids = Enum.at(ids, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        type_expires =
          Map.get(controversial_week_expires, type)
          |> Map.put(date, DateTime.utc_now)
        controversial_week_expires = Map.put(controversial_week_expires, type, type_expires)
        expires = Map.put(expires, :controversial_week, controversial_week_expires)
        stash =
          Map.put(stash, :expires, expires)
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end

  # COMMENT GETTERS
  def handle_call({:get_post_comments, comment_id, page}, _from, stash = %{post_comments: post_comments, comments: comments, expires: expires = %{post_comments: post_comments_expires}}) do
    comment_id = make_sure_int comment_id
    single_post_comments =  Map.get(post_comments, comment_id, [])
    ids = Enum.at(single_post_comments, page)
    case ids do
      nil ->
        {:reply, nil, stash}
      ids ->
        post_comments_expires = Map.put(post_comments_expires, comment_id, DateTime.utc_now)
        expires = Map.put(expires, :post_comments, post_comments_expires)
        stash =
          Map.put(stash, :expires, expires)
        payload =
          ids
          |> Enum.map(fn id -> comments[id] end)
        {:reply, payload, stash}
    end
  end
  def handle_call({:get_comment, comment_id}, _from, stash = %{comments: comments}) do
    comment_id = make_sure_int comment_id
    comment =  Map.get(comments, comment_id)
    {:reply, {:ok, comment}, stash}
  end


  # COMMENT PUTTERS
  def handle_cast({:put_comment, comment}, stash = %{comments: comments}) do
    comments = Map.put(comments, comment.id, comment)
    {:noreply, Map.put(stash, :comments, comments)}
  end
  def handle_cast({:put_post_comments, comment_id, comment_post_comments, page}, stash = %{comments: comments, post_comments: post_comments, expires: expires = %{post_comments: post_comments_expires}}) do

    post_comments_expires = Map.put(post_comments_expires, comment_id, DateTime.utc_now)
    expires = Map.put(expires, :post_comments, post_comments_expires)

    ids = Enum.map(comment_post_comments, &(&1.id))
    single_post_comments = Map.get(post_comments, comment_id, [])
    single_post_comments = put_new_child_ids(single_post_comments, ids, page)

    post_comments = Map.put(post_comments, comment_id, single_post_comments)

    comments = Enum.reduce(comment_post_comments, comments, fn comment, comment_map ->
      Map.put_new(comment_map, comment.id, comment)
    end)
    stash =
      stash
      |> Map.put(:expires, expires)
      |> Map.put(:post_comments, post_comments)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end

  # POST PUTTERS
  # def handle_cast({:put_posts, type, order_by, page, date})
  def handle_cast({:put_posts, posts, type, :recent, page, _date}, stash = %{recent: recent_posts, comments: comments}) do
    type_posts = Map.get(recent_posts, type, [])
    comments = put_new_children(comments, posts)
    ids = Enum.map(posts, fn post -> post.id end)
    type_posts = put_new_child_ids(type_posts, ids, page)
    recent_posts = Map.put(recent_posts, type, type_posts)
    stash =
      stash
      |> Map.put(:comments, comments)
      |> Map.put(:recent, recent_posts)
    {:noreply, stash}
  end
  def handle_cast({:put_posts, posts, type, :top_all_time, page, _date}, stash = %{top_all_time: all_time, comments: comments}) do
    type_posts = Map.get(all_time, type, [])

    comments = put_new_children(comments, posts)
    ids = Enum.map(posts, fn post -> post.id end)
    type_posts = put_new_child_ids(type_posts, ids, page)
    all_time = Map.put(all_time, type, type_posts)

    stash =
      stash
      |> Map.put(:comments, comments)
      |> Map.put(:top_all_time, all_time)
    {:noreply, stash}
  end
  def handle_cast({:put_posts, posts, type, :controversial_all_time, page, _date}, stash = %{controversial_all_time: all_time, comments: comments}) do
    type_posts = Map.get(all_time, type, [])

    comments = put_new_children(comments, posts)
    ids = Enum.map(posts, fn post -> post.id end)
    type_posts = put_new_child_ids(type_posts, ids, page)
    all_time = Map.put(all_time, type, type_posts)

    stash =
      stash
      |> Map.put(:comments, comments)
      |> Map.put(:controversial_all_time, all_time)
    {:noreply, stash}
  end
  def handle_cast({:put_posts, posts, type, :top_day, page, date}, stash = %{top_day: top_day, comments: comments, expires: expires = %{top_day: top_day_expires}}) do
    type_posts = Map.get(top_day, type)
    day_posts = Map.get(type_posts, date, [])

    comments = put_new_children(comments, posts)
    ids = Enum.map(posts, fn post -> post.id end)
    day_posts = put_new_child_ids(day_posts, ids, page)
    type_posts = Map.put(type_posts, date, day_posts)
    top_day = Map.put(top_day, type, type_posts)

    type_expires =
      Map.get(top_day_expires, type)
      |> Map.put(date, DateTime.utc_now)
    top_day_expires = Map.put(top_day_expires, type, type_expires)
    expires = Map.put(expires, :top_day, top_day_expires)

    stash =
      stash
      |> Map.put(:expires, expires)
      |> Map.put(:comments, comments)
      |> Map.put(:top_day, top_day)
    {:noreply, stash}
  end
  def handle_cast({:put_posts, posts, type, :top_week, page, date}, stash = %{top_week: top_week, comments: comments, expires: expires = %{top_week: top_week_expires}}) do
    type_posts = Map.get(top_week, type)
    week_posts = Map.get(type_posts, date, [])

    comments = put_new_children(comments, posts)
    ids = Enum.map(posts, fn post -> post.id end)
    week_posts = put_new_child_ids(week_posts, ids, page)
    type_posts = Map.put(type_posts, date, week_posts)
    top_week = Map.put(top_week, type, type_posts)

    type_expires =
      Map.get(top_week_expires, type)
      |> Map.put(date, DateTime.utc_now)
    top_week_expires = Map.put(top_week_expires, type, type_expires)
    expires = Map.put(expires, :top_week, top_week_expires)


    stash =
      stash
      |> Map.put(:expires, expires)
      |> Map.put(:comments, comments)
      |> Map.put(:top_week, top_week)
    {:noreply, stash}
  end
  def handle_cast({:put_posts, posts, type, :controversial_day, page, date}, stash = %{controversial_day: controversial_day, comments: comments, expires: expires = %{controversial_day: controversial_day_expires}}) do
    type_posts = Map.get(controversial_day, type)
    day_posts = Map.get(type_posts, date, [])

    comments = put_new_children(comments, posts)
    ids = Enum.map(posts, fn post -> post.id end)
    day_posts = put_new_child_ids(day_posts, ids, page)
    type_posts = Map.put(type_posts, date, day_posts)
    controversial_day = Map.put(controversial_day, type, type_posts)

    type_expires =
      Map.get(controversial_day_expires, type)
      |> Map.put(date, DateTime.utc_now)
    controversial_day_expires = Map.put(controversial_day_expires, type, type_expires)
    expires = Map.put(expires, :controversial_day, controversial_day_expires)

    stash =
      stash
      |> Map.put(:expires, expires)
      |> Map.put(:comments, comments)
      |> Map.put(:controversial_day, controversial_day)
    {:noreply, stash}
  end
  def handle_cast({:put_posts, posts, type, :controversial_week, page, date}, stash = %{controversial_week: controversial_week, comments: comments, expires: expires = %{controversial_week: controversial_week_expires}}) do
    type_posts = Map.get(controversial_week, type)
    week_posts = Map.get(type_posts, date, [])

    comments = put_new_children(comments, posts)
    ids = Enum.map(posts, fn post -> post.id end)
    week_posts = put_new_child_ids(week_posts, ids, page)
    type_posts = Map.put(type_posts, date, week_posts)
    controversial_week = Map.put(controversial_week, type, type_posts)

    type_expires =
      Map.get(controversial_week_expires, type)
      |> Map.put(date, DateTime.utc_now)
    controversial_week_expires = Map.put(controversial_week_expires, type, type_expires)
    expires = Map.put(expires, :controversial_week, controversial_week_expires)

    stash =
      stash
      |> Map.put(:expires, expires)
      |> Map.put(:comments, comments)
      |> Map.put(:controversial_week, controversial_week)
    {:noreply, stash}
  end

  # NEW VOTES OR COMMENTS
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
  def handle_cast({:new_comment, comment = %{id: id, image_id: nil, document_id: nil}}, stash = %{recent: recent = %{posts: [recent_posts | _]}, comments: comments}) do
    comments = Map.put(comments, id, comment)
    recent_posts = [[id | Enum.take(recent_posts, 19)]]
    recent = Map.put(recent, :posts, recent_posts)
    stash =
      stash
      |> Map.put(:recent, recent)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end
  def handle_cast({:new_comment, comment = %{id: id, document_id: nil}}, stash = %{recent:  recent = %{images: [recent_images | _]}, comments: comments}) do
    comments = Map.put(comments, id, comment)
    recent_images = [[id | Enum.take(recent_images, 19)]]
    recent = Map.put(recent, :images, recent_images)
    stash =
      stash
      |> Map.put(:recent, recent)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end
  def handle_cast({:new_comment, comment = %{id: id}}, stash = %{recent: recent = %{documents: [recent_documents | _]}, comments: comments}) do
    comments = Map.put(comments, id, comment)
    recent_documents = [[id | Enum.take(recent_documents, 19)]]
    recent = Map.put(recent, :documents, recent_documents)
    stash =
      stash
      |> Map.put(:recent, recent)
      |> Map.put(:comments, comments)
    {:noreply, stash}
  end
  def handle_cast({:new_comment_comment, comment = %{id: id, parent_id: parent_id}}, stash = %{post_comments: all_post_comments, comments: comments}) do
    parent_comment =
      Map.get(comments, parent_id)
    parent_comment = Map.put(parent_comment, :comment_count, parent_comment.comment_count + 1)
    comments =
      comments
      |> Map.put(id, comment)
      |> Map.put(parent_id, parent_comment)
    stash =
      stash
      |> Map.put(:comments, comments)

    post_comments = Map.get(all_post_comments, parent_id)
    case post_comments do
      nil ->
        {:noreply, stash}
      [] ->
        all_post_comments = Map.put(all_post_comments, parent_id, [[id]])
        stash =
          stash
          |> Map.put(:post_comments, all_post_comments)
        {:noreply, stash}
      post_comments ->
        top_post_comments = Enum.at(post_comments, 0)
        top_post_comments = [id | top_post_comments]
        post_comments = List.replace_at(post_comments, 0, top_post_comments)
        all_post_comments = Map.put(all_post_comments, parent_id, post_comments)
        stash =
          stash
          |> Map.put(:post_comments, all_post_comments)
        {:noreply, stash}
    end
  end

  # INFO
  def handle_info(:update_stash, stash) do
    # TODO: why not make this happen in a separate process so it doesn't clog up the server in the mean time.  But then data will be lost that comes in during this time.  Need a way to pause data collection during this time?
    stash =
      delete_expired_comments(stash)
      |> delete_expired_top_days()
      |> delete_expired_controversial_days()
      |> delete_expired_top_weeks()
      |> delete_expired_controversial_weeks()
      |> update_all_time_to_nil()
      |> update_todays_posts_to_nil()
      |> delete_unused_comments()


    :timer.send_after(@update, :update_stash)
    {:noreply, stash}
  end
  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end


  # HELPERS
  defp delete_expired_comments(stash = %{expires: expires}) do
    # map_to_delete = :maps.filter(fn _, exp -> DateTime.compare(exp, Timex.shift(DateTime.utc_now, hours: @hours_to_expire_comments)) == :lt end, comments_posts)
    # post_comments = Map.drop(post_comments, Map.keys(map_to_delete))
    # comments_posts = Map.drop(comments_posts, Map.keys(map_to_delete))
    # expires = Map.put(expires, :comments_posts, comments_posts)
    # Map.put(stash, :post_comments, post_comments)
    # |> Map.put(:expires, expires)
    # going to nilify all of these so the ranking of the posts is made accurate
    expires = Map.put(expires, :post_comments, %{})
    Map.put(stash, :post_comments, %{})
    |> Map.put(:expires, expires)
  end
  defp delete_expired_top_weeks(stash = %{top_week: top_week, expires: expires = %{top_week: top_week_expires}}) do
    to_delete =
      top_week_expires \
      |> Map.keys \
      |> Enum.reduce([], fn board_type, list ->
        maps_to_delete = :maps.filter(
          fn _, exp -> DateTime.compare(exp, Timex.shift(DateTime.utc_now, hours: @hours_to_expire_comments)) == :lt end,
          top_week_expires[board_type]
          )
        List.flatten(Map.keys(maps_to_delete), list)
      end)
    top_week =
      Map.keys(top_week)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(top_week[key], to_delete))
      end)
    top_week_expires =
      Map.keys(top_week)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(top_week_expires[key], to_delete))
      end)
    expires = Map.put(expires, :top_week, top_week_expires)
    Map.put(stash, :top_week, top_week)
    |> Map.put(:expires, expires)
  end
  defp delete_expired_controversial_weeks(stash = %{controversial_week: controversial_week, expires: expires = %{controversial_week: controversial_week_expires}}) do
    to_delete =
      controversial_week_expires \
      |> Map.keys \
      |> Enum.reduce([], fn board_type, list ->
        maps_to_delete = :maps.filter(
          fn _, exp -> DateTime.compare(exp, Timex.shift(DateTime.utc_now, hours: @hours_to_expire_comments)) == :lt end,
          controversial_week_expires[board_type]
          )
        List.flatten(Map.keys(maps_to_delete), list)
      end)
    controversial_week =
      Map.keys(controversial_week)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(controversial_week[key], to_delete))
      end)
    controversial_week_expires =
      Map.keys(controversial_week)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(controversial_week_expires[key], to_delete))
      end)
    expires = Map.put(expires, :controversial_week, controversial_week_expires)
    Map.put(stash, :controversial_week, controversial_week)
    |> Map.put(:expires, expires)
  end
  defp delete_expired_top_days(stash = %{top_day: top_day, expires: expires = %{top_day: top_day_expires}}) do
    to_delete =
      top_day_expires \
      |> Map.keys \
      |> Enum.reduce([], fn board_type, list ->
        maps_to_delete = :maps.filter(
          fn _, exp -> DateTime.compare(exp, Timex.shift(DateTime.utc_now, hours: @hours_to_expire_comments)) == :lt end,
          top_day_expires[board_type]
          )
        List.flatten(Map.keys(maps_to_delete), list)
      end)
    top_day =
      Map.keys(top_day)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(top_day[key], to_delete))
      end)
    top_day_expires =
      Map.keys(top_day)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(top_day_expires[key], to_delete))
      end)
    expires = Map.put(expires, :top_day, top_day_expires)
    Map.put(stash, :top_day, top_day)
    |> Map.put(:expires, expires)
  end
  defp delete_expired_controversial_days(stash = %{controversial_day: controversial_day, expires: expires = %{controversial_day: controversial_day_expires}}) do
    to_delete =
      controversial_day_expires \
      |> Map.keys \
      |> Enum.reduce([], fn board_type, list ->
        maps_to_delete = :maps.filter(
          fn _, exp -> DateTime.compare(exp, Timex.shift(DateTime.utc_now, hours: @hours_to_expire_comments)) == :lt end,
          controversial_day_expires[board_type]
          )
        List.flatten(Map.keys(maps_to_delete), list)
      end)
    controversial_day =
      Map.keys(controversial_day)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(controversial_day[key], to_delete))
      end)
    controversial_day_expires =
      Map.keys(controversial_day)
      |> Enum.reduce(%{}, fn key, map ->
        Map.put(map, key, Map.drop(controversial_day_expires[key], to_delete))
      end)
    expires = Map.put(expires, :controversial_day, controversial_day_expires)
    Map.put(stash, :controversial_day, controversial_day)
    |> Map.put(:expires, expires)
  end
  defp update_all_time_to_nil(stash) do
    stash
    |> Map.put(:top_all_time, %{posts: [], images: [], documents: []})
    |> Map.put(:controversial_all_time, %{posts: [], images: [], documents: []})
    |> Map.put(:recent, %{posts: [], images: [], documents: []})
  end
  defp update_todays_posts_to_nil(stash = %{top_day: top_day}) do
    date = Timex.to_date(Timex.now)
    top_day
    |> Map.keys
    |> Enum.reduce(%{}, fn key, map ->
      type_map = Map.drop(top_day[key], [date])
      Map.put(map, key, type_map)
    end)
    Map.put(stash, :top_day, top_day)
  end
  defp delete_unused_comments(stash = %{comments: comments}) do

    comment_ids =
      List.flatten(Map.values(stash.top_all_time))
      |> List.flatten(Map.values(stash.controversial_all_time))
      |> List.flatten(Map.values(stash.recent))
      |> List.flatten(Map.values(stash.post_comments))
      |> List.flatten(get_comment_ids_from_stash_map(stash.controversial_day))
      |> List.flatten(get_comment_ids_from_stash_map(stash.controversial_week))
      |> List.flatten(get_comment_ids_from_stash_map(stash.top_day))
      |> List.flatten(get_comment_ids_from_stash_map(stash.top_week))
      |> List.flatten
      |> Enum.uniq
    comment_ids = Map.keys(comments) -- comment_ids
    comments = Map.drop(comments, comment_ids)
    Map.put(stash, :comments, comments)
  end
  def get_comment_ids_from_stash_map(map) do
    Map.keys(map)
    |> Enum.reduce([], fn key, list ->
      List.flatten(list, Map.values(map[key]))
    end)
    |> List.flatten
  end
  # not going to sort comments, just nilify and pull from db
  # defp sort_all_comments_lists_by_votes(stash = %{comments: comments}) do
  #   stash
  #   |> Map.put(:top_week_posts, sort_all_lists(stash.top_day_posts, comments))
  #   |> Map.put(:top_week_posts, sort_all_lists(stash.post_comments, comments))
  #   |> Map.put(:all_time_top_posts, sort_list(stash.all_time_top_posts, comments))
  # end
  # defp sort_list(nil, _comments) do
  #   nil
  # end
  # defp sort_list(list, comments) do
  #   Enum.sort_by(list, fn id -> -comments[id].points end)
  # end
  # defp sort_all_lists(map_of_lists, comments) do
  #   keys = Map.keys(map_of_lists)
  #   Enum.reduce(keys, %{}, fn key, map ->
  #     Map.put(map, key, sort_list(map_of_lists[key], comments))
  #   end)
  # end
  # defp sort_comments_by_votes(comments) do
  #   Enum.sort_by(comments, fn _ -> &(&1.points) end) \
  #   |> Enum.map(fn {_id, comment} -> comment.id end)
  # end


  defp make_sure_int(id) when is_integer(id), do: id
  defp make_sure_int(id) when is_binary(id), do: String.to_integer(id)
  defp put_new_children(children, new_children)
  defp put_new_children(children, []), do: children
  defp put_new_children(children, [new_child | new_children]) do
    put_new_children(
      Map.put(children, new_child.id, new_child),
      new_children
    )
  end
  defp put_new_child_ids(main_list, new_sublist, page)
  defp put_new_child_ids(main_list, new_sublist, page) when (length(main_list) <= page) do
    List.insert_at(main_list, page, new_sublist)
  end
  defp put_new_child_ids(main_list, _new_sublist, page) do
    List.insert_at(main_list, page, nil)
  end
end
