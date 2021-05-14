defmodule Camp1Web.UserCampChannel do
  use Camp1Web, :channel
  alias Camp1.{CampHome, CampServer, UserServer, Topics, Board, PublicChat, Reputation, Reactions, Audio, Manifesto}
  alias Camp1.Manifesto.ManifestoServer
  alias Camp1.Board.{Comment, BoardServer}
  alias Camp1Web.CampView
  alias Camp1.UserServer.UserCompare

  def join("user_camp_channel:" <> camp_id, _params, socket) do
    camp_id = String.to_integer(camp_id)
    start_camp_servers(camp_id)
    agreement = UserServer.get_user_agreement(socket.assigns[:user_id], camp_id)
    handle = Reputation.get_handle(socket.assigns[:user_id], camp_id)
    socket =
      socket
      |> assign(:camp_id, camp_id)
      |> assign(:agreement, agreement)
      |> assign(:handle, handle)
    {:ok, socket}
  end

  # MAIN NAV
  def handle_in("expand_menu", %{"expand" => expand}, socket) do
    html = get_main_html(socket.assigns[:camp_id], expand,  socket.assigns[:agreement], socket.assigns[:user_id])
    {:reply, {:ok, %{html: html}}, socket}
  end

  # OVERVIEW
  def handle_in("init_overview", _params, socket) do
    data = CampServer.get_core_camp_data(socket.assigns[:camp_id])
    camp_html =
      Phoenix.View.render_to_string(CampView, "users/_user_overview.html", %{data: data })

    {:reply, {:ok, %{html: camp_html}}, socket}
  end
  def handle_in("expand_overview", %{"action" => action}, socket) do
    html = get_overview_html(socket.assigns[:camp_id], action,  socket.assigns[:agreement], socket.assigns[:user_id])
    {:reply, {:ok, %{html: html}}, socket}
  end



  # SUBCAMPS
  def handle_in("init_subcamps", _params, socket) do
    camps = CampServer.get_children(socket.assigns[:camp_id], :newest, 0)
    html =
      Phoenix.View.render_to_string(CampView, "users/subcamps/_user_subcamps.html", %{data: %{camps: camps}})

    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("sort_subcamps", %{"sort_by" => sort_by, "date" => date}, socket) do
    sort_by = String.to_atom sort_by
    camps = CampServer.get_children(socket.assigns[:camp_id], sort_by, date, 0)
    html =
      Phoenix.View.render_to_string(CampView, "users/subcamps/_user_subcamps_list.html", %{camps: camps})

    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("sort_subcamps", %{"sort_by" => sort_by}, socket) do
    sort_by = String.to_atom sort_by
    camps = CampServer.get_children(socket.assigns[:camp_id], sort_by, 0)
    html =
      Phoenix.View.render_to_string(CampView, "users/subcamps/_user_subcamps_list.html", %{camps: camps})

    {:reply, {:ok, %{html: html}}, socket}
  end


  # OPPONENTS
  def handle_in("init_opponents", _params, socket) do
    top_opponents = CampServer.get_opponents(socket.assigns[:camp_id], :biggest, 0)
    case top_opponents do
      [] ->
        camp_html =
          Phoenix.View.render_to_string(CampView, "users/_user_no_opponents.html", %{agreement: socket.assigns[:agreement]})
        {:reply, {:ok, %{html: camp_html}}, socket}
      top_opponents ->
        opponent_view = CampHome.get_opponent_view(socket.assigns[:camp_id], List.first(top_opponents)[:id])
        camp_html =
          Phoenix.View.render_to_string(CampView, "users/_user_opponents.html", top_opponents: top_opponents, opponent_view: opponent_view)
        {:reply, {:ok, %{html: camp_html}}, socket}
    end
  end
  def handle_in("opponent_view", %{"opponent_id" => id}, socket) do
    id = String.to_integer id
    opponent_view = CampHome.get_opponent_view(socket.assigns[:camp_id], id)
    opponent_view_html =
      Phoenix.View.render_to_string(CampView, "users/_user_opponent_details.html", opponent_view: opponent_view)
    {:reply, {:ok, %{html: opponent_view_html}}, socket}
  end


  # COMPARE
  def handle_in("init_compare", _params, socket) do
    compare = UserCompare.compare_user_to_camp(socket.assigns[:user_id], socket.assigns[:camp_id])
    subject_names = Topics.TopicsServer.get_top_subject_names
    html =
      Phoenix.View.render_to_string(CampView, "users/_user_compare.html", %{compare: compare, subject_names: subject_names, compare_type: :camp})


    {:reply, {:ok, %{html: html}}, socket}
  end


  # BOARD
  def handle_in("expand_board", %{"action" => action}, socket) do
    html = get_board_html(socket.assigns[:camp_id], action,  socket.assigns[:agreement], socket.assigns[:user_id])
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("board_select", %{"post_type" => post_type, "board_type" => board_type, "range" => range, "date" => date}, socket) do
    post_type = String.to_atom post_type
    board_type = String.to_atom board_type
    {order_by, date} = parse_order_by(post_type, range, date)
    html_data = %{
      board_type: board_type,
      next_page: 1,
      date: date,
      camp_id: socket.assigns[:camp_id],
      order_by: order_by,
      posts: BoardServer.get_posts(socket.assigns[:camp_id], board_type, order_by, 0, date),
      user_vote_data: UserServer.get_vote_data(socket.assigns[:user_id], socket.assigns[:camp_id])
    }
    html = Phoenix.View.render_to_string(CampView, "users/board/_user_board_posts.html", html_data)
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("load_form", %{"id" => id}, socket) do
    case socket.assigns[:agreement] do
      false ->
        {:noreply, socket}
      true ->
        changeset = Comment.changeset(%Comment{}, %{})
        html =
          Phoenix.View.render_to_string(CampView, "users/board/_user_board_form.html", %{changeset: changeset, camp_id: socket.assigns[:camp_id], comment_id: id})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("load_more_posts", %{"order_by" => order_by, "board_type" => board_type, "date" => date, "page" => page}, socket) do
    board_type = String.to_atom board_type
    order_by = String.to_atom order_by
    page = String.to_integer page
    html_data = %{
      board_type: board_type,
      next_page: page + 1,
      date: date,
      camp_id: socket.assigns[:camp_id],
      order_by: order_by,
      posts: BoardServer.get_posts(socket.assigns[:camp_id], board_type, order_by, page, date),
      user_vote_data: UserServer.get_vote_data(socket.assigns[:user_id], socket.assigns[:camp_id])
    }
    html = Phoenix.View.render_to_string(CampView, "users/board/_user_board_posts.html", html_data)
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("load_comments", %{"post_id" => post_id, "board_type" => board_type, "page" => page}, socket) do
    post_id = String.to_integer post_id
    data = %{
      posts: BoardServer.get_comments(post_id, socket.assigns[:camp_id], page),
      next_page: page + 1,
      user_vote_data: UserServer.get_vote_data(socket.assigns[:user_id], socket.assigns[:camp_id]),
      board_type: board_type,
      parent_id: post_id,
      camp_id: socket.assigns[:camp_id]
    }
    html =
      Phoenix.View.render_to_string(CampView, "users/board/_user_board_comments.html", data)

    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("load_more_comments", %{"post_id" => post_id, "page" => page}, socket) do
    case socket.assigns[:agreement] do
      false ->
        {:noreply, socket}
      true ->
        board_data = Board.get_comments(post_id, String.to_integer(page), socket.assigns[:camp_id], %{include_images?: false})
        user_vote_data = UserServer.get_vote_data(socket.assigns[:user_id], socket.assigns[:camp_id])
        html =
          Phoenix.View.render_to_string(CampView, "users/board/_user_board_comments.html", %{board_data: board_data, user_vote_data: user_vote_data})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("new_vote", %{"id" => id, "value" => value, "update" => updating?, "old_vote" => old_vote?, "flip_vote" => flip_vote?}, socket) do
    new_votes = Map.get(socket.assigns, :new_votes, %{})
    comment_id = String.to_integer(id)
    user_id = socket.assigns[:user_id]
    new_votes = add_vote_to_map_if_it_exists(new_votes, comment_id, user_id, old_vote?)
    value = String.to_integer(value)
    vote = new_votes[comment_id]
    case vote do
      nil ->
        vote = Reactions.create_or_update_vote(%{comment_id: comment_id, user_id: user_id, value: value}, nil, updating?, old_vote?)
        UserServer.put_new_vote(user_id, socket.assigns[:camp_id], comment_id, value, updating?)
        Board.put_new_vote_to_server(socket.assigns[:camp_id], comment_id, value, %{flip_vote?: flip_vote?, updating?: updating?})
        new_votes = Map.put(new_votes, comment_id, vote)
        {:reply, :ok, assign(socket, :new_votes, new_votes)}
      vote ->
        updating? = vote.value == value
        flip_vote? = vote.value == -value
        vote = Reactions.create_or_update_vote(%{comment_id: comment_id, user_id: user_id, value: value}, vote, updating?, old_vote?)
        UserServer.put_new_vote(user_id, socket.assigns[:camp_id], comment_id, value, updating?)
        Board.put_new_vote_to_server(socket.assigns[:camp_id], comment_id, value, %{flip_vote?: flip_vote?, updating?: updating?})
        new_votes = Map.put(new_votes, comment_id, vote)
        {:reply, :ok, assign(socket, :new_votes, new_votes)}
    end
  end
  def handle_in("load_image_form", _params, socket) do
    case socket.assigns[:agreement] do
      false ->
        {:noreply, socket}
      true ->
        changeset = Comment.changeset(%Comment{}, %{})
        html =
          Phoenix.View.render_to_string(CampView, "users/board/_user_image_form.html", %{changeset: changeset, camp_id: socket.assigns[:camp_id]})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("load_document_form", _params, socket) do
    case socket.assigns[:agreement] do
      false ->
        {:noreply, socket}
      true ->
        changeset = Comment.changeset(%Comment{}, %{})
        html =
          Phoenix.View.render_to_string(CampView, "users/board/_user_document_form.html", %{changeset: changeset, camp_id: socket.assigns[:camp_id]})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("load_image", %{"image_id" => image_id}, socket) do
    case socket.assigns[:agreement] do
      false ->
        {:noreply, socket}
      true ->
        html =
          Phoenix.View.render_to_string(CampView, "users/board/_user_board_image.html", %{image_id: image_id})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end


  # CHAT ROOM
  def handle_in("expand_discussion", %{"action" => action}, socket) do
    html = get_discussion_html(socket.assigns[:camp_id], action,  socket.assigns[:agreement], socket.assigns[:user_id])
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("init_chat_room", _params, socket) do
    case socket.assigns[:agreement] do
      false ->
        {:noreply, socket}
      true ->
        messages = PublicChat.get_recent_messages(socket.assigns[:camp_id], 0)
        html =
          Phoenix.View.render_to_string(CampView, "users/_user_chat_room.html", %{data: %{messages: messages}})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end


  # MANIFESTO
  def handle_in("expand_manifesto", %{"action" => action}, socket) do
    html = get_manifesto_html(socket.assigns[:camp_id], action,  socket.assigns[:agreement], socket.assigns[:user_id])
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("submit_manifesto", %{"content" => content, "delta" => delta}, socket) do
    {:ok, _manifesto} = Manifesto.create_manifesto(%{
      content: content,
      delta: delta,
      camp_id: socket.assigns[:camp_id],
      user_id: socket.assigns[:user_id],
      status: :proposed
      })

    {:reply, :ok, socket}
  end
  def handle_in("manifesto_version_select", %{"version" => manifesto_id}, socket) do
    camp_id = socket.assigns[:camp_id]
    manifesto_id = String.to_integer manifesto_id
    content = ManifestoServer.get_version(camp_id, manifesto_id)
    {:reply, {:ok, %{html: content}}, socket}
  end
  def handle_in("manifesto_vote", %{"version" => manifesto_id, "value" => value}, socket) do
    user_id = socket.assigns[:user_id]
    camp_id = socket.assigns[:camp_id]
    manifesto_id = String.to_integer manifesto_id
    value = String.to_integer value
    current_vote = UserServer.get_manifesto_vote(user_id, camp_id, manifesto_id)
    case current_vote do
      nil ->
        Manifesto.create_vote(%{
          record_id: manifesto_id,
          user_id: user_id,
          value: value
          })
      current_vote ->
        Manifesto.update_vote(user_id, camp_id, manifesto_id, value, current_vote)
    end
    {:reply, :ok, socket}
  end

  # CREATE SUBCAMP
  def handle_in("init_create_subcamp", _params, socket) do
    html =
      Phoenix.View.render_to_string(CampView, "users/_user_create_subcamp.html", %{})


    {:reply, {:ok, %{html: html}}, socket}
  end


  # LEAVE
  def handle_in("init_leave", _params, socket) do
    html =
      Phoenix.View.render_to_string(CampView, "users/_user_leave.html", %{})


    {:reply, {:ok, %{html: html}}, socket}
  end


  # JOIN
  def handle_in("init_join", _params, socket) do
    html =
      Phoenix.View.render_to_string(CampView, "users/_user_join.html", %{})

    {:reply, {:ok, %{html: html}}, socket}
  end



  # PRIVATE HELPERS
  defp get_main_html(camp_id, expand, agreement, user_id)
  defp get_main_html(camp_id, "overview", _agreement, _user_id) do
    data = CampServer.get_core_camp_data(camp_id)
    Phoenix.View.render_to_string(CampView, "users/_expand_overview.html", %{data: data, sub_menu: nil, subsub_menu: nil })
  end
  defp get_main_html(camp_id, "board", _agreement, user_id) do
    data = %{
      next_page: 1,
      board_type: :posts,
      date: nil,
      camp_id: camp_id,
      order_by: :recent,
      posts: BoardServer.get_posts(camp_id, :posts, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
    Phoenix.View.render_to_string(CampView, "users/_expand_board.html", %{data: data, sub_menu: nil, subsub_menu: nil  })
  end
  defp get_main_html(camp_id, "discussion", _agreement, _user_id) do
    messages = PublicChat.get_recent_messages(camp_id, 0)
    Phoenix.View.render_to_string(CampView, "users/_expand_discussion.html", %{data: %{messages: messages}, sub_menu: nil, subsub_menu: nil })
  end
  defp get_main_html(camp_id, "manifesto", _agreement, user_id) do
    data = %{
      manifesto: Manifesto.get_live_manifesto(camp_id),
      proposed: Manifesto.get_proposed(camp_id),
      history: Manifesto.get_history(camp_id),
      votes: UserServer.get_camp_manifesto_votes(user_id, camp_id)
    }
    Phoenix.View.render_to_string(CampView, "users/_expand_manifesto.html", %{data: data, sub_menu: nil, subsub_menu: nil })
  end
  defp get_main_html(_camp_id, "manage", _agreement, _user_id) do
    Phoenix.View.render_to_string(CampView, "users/_expand_manage.html", %{data: %{}, sub_menu: nil, subsub_menu: nil })
  end

  defp get_board_html(camp_id, expand, agreement, user_id)
  defp get_board_html(camp_id, "posts", _agreement, user_id) do
    data = %{
      next_page: 1,
      board_type: :posts,
      date: nil,
      order_by: :recent,
      camp_id: camp_id,
      posts: BoardServer.get_posts(camp_id, :posts, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
    Phoenix.View.render_to_string(CampView, "users/board/_user_board.html", %{data: data})
  end
  defp get_board_html(camp_id, "images", _agreement, user_id) do
    data = %{
      next_page: 1,
      board_type: :images,
      camp_id: camp_id,
      date: nil,
      order_by: :recent,
      posts: BoardServer.get_posts(camp_id, :images, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
    Phoenix.View.render_to_string(CampView, "users/board/_user_board.html", %{data: data})
  end
  defp get_board_html(camp_id, "documents", _agreement, user_id) do
    data = %{
      next_page: 1,
      camp_id: camp_id,
      board_type: :documents,
      date: nil,
      order_by: :recent,
      posts: BoardServer.get_posts(camp_id, :documents, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
    Phoenix.View.render_to_string(CampView, "users/board/_user_board.html", %{data: data})
  end
  defp get_board_html(_camp_id, "reasons", _agreement, _user_id) do
    Phoenix.View.render_to_string(CampView, "users/reasons/_user_reasons_board.html", %{data: %{}})
  end

  defp get_discussion_html(camp_id, expand, agreement, user_id)
  defp get_discussion_html(camp_id, "text", _agreement, _user_id) do
    messages = PublicChat.get_recent_messages(camp_id, 0)
    Phoenix.View.render_to_string(CampView, "users/_user_chat_room.html", %{data: %{messages: messages}})
  end
  defp get_discussion_html(camp_id, "audio", _agreement, _user_id) do
    data = %{
      audio_status: Audio.get_camp_channel_status(camp_id),
      camp_id: camp_id,
    }
    Phoenix.View.render_to_string(CampView, "users/_user_audio_room.html", %{data: data})
  end

  defp get_manifesto_html(camp_id, expand, agreement, user_id)
  defp get_manifesto_html(camp_id, "manifesto", _agreement, user_id) do
    data = %{
      manifesto: ManifestoServer.get_live_manifesto(camp_id),
      proposed: ManifestoServer.get_proposed(camp_id),
      history: ManifestoServer.get_history(camp_id),
      votes: UserServer.get_camp_manifesto_votes(user_id, camp_id)
    }
    Phoenix.View.render_to_string(CampView, "users/_user_manifesto.html", %{data: data})
  end
  defp get_manifesto_html(_camp_id, "lexicon", _agreement, _user_id) do
    Phoenix.View.render_to_string(CampView, "users/_user_lexicon.html", %{data: %{}})
  end

  defp get_overview_html(camp_id, "activity", _agreement, _user_id) do
    data = CampServer.get_core_camp_data(camp_id)
    Phoenix.View.render_to_string(CampView, "users/_user_overview.html", %{data: data })
  end
  defp get_overview_html(camp_id, "subcamps", _agreement, _user_id) do
    camps = CampServer.get_children(camp_id, :newest, 0)
    Phoenix.View.render_to_string(CampView, "users/subcamps/_user_subcamps.html", %{data: %{camps: camps}})
  end
  defp get_overview_html(camp_id, "opponents", agreement, _user_id) do
    top_opponents = CampServer.get_opponents(camp_id, :biggest, 0)
    case top_opponents do
      [] ->
        Phoenix.View.render_to_string(CampView, "users/_user_no_opponents.html", %{agreement: agreement})
      top_opponents ->
        opponent_view = CampHome.get_opponent_view(camp_id, List.first(top_opponents)[:id])
        data = %{
          top_opponents: top_opponents, opponent_view: opponent_view
        }
        Phoenix.View.render_to_string(CampView, "users/_user_opponents.html", data: data )
    end
  end
  defp get_overview_html(camp_id, "compare", _agreement, user_id) do
    compare = UserCompare.compare_user_to_camp(user_id, camp_id)
    subject_names = Topics.TopicsServer.get_top_subject_names
    data = %{compare: compare, subject_names: subject_names, compare_type: :camp}
    Phoenix.View.render_to_string(CampView, "users/_user_compare.html", data: data)
  end

  defp parse_order_by(post_type, range, date)
  defp parse_order_by(:recent, _range, _date), do: {:recent, nil}
  defp parse_order_by(:top, "today", _date), do: {:top_day, todays_date()}
  defp parse_order_by(:top, "yesterday", _date), do: {:top_day, yesterdays_date()}
  defp parse_order_by(:top, "this_week", _date), do: {:top_week, this_weeks_date()}
  defp parse_order_by(:top, "all_time", _date), do: {:top_all_time, nil}
  defp parse_order_by(:top, "day", date), do: {:top_day, date}
  defp parse_order_by(:top, "week", date), do: {:top_week, weeks_date(date)}
  defp parse_order_by(:controversial, "today", _date), do: {:controversial_day, todays_date()}
  defp parse_order_by(:controversial, "yesterday", _date), do: {:controversial_day, yesterdays_date()}
  defp parse_order_by(:controversial, "this_week", _date), do: {:controversial_week, this_weeks_date()}
  defp parse_order_by(:controversial, "all_time", _date), do: {:controversial_all_time, nil}
  defp parse_order_by(:controversial, "day", date), do: {:controversial_day, date}
  defp parse_order_by(:controversial, "week", date), do: {:controversial_week, weeks_date(date)}

  defp start_camp_servers(id) do
    CampServer.start_camp_supervisor(id)
  end
  def add_vote_to_map_if_it_exists(new_votes, _comment_id, _user_id, _old_vote = false) do
    new_votes
  end
  def add_vote_to_map_if_it_exists(new_votes, comment_id, user_id, _old_vote = true) do
    case new_votes[comment_id] do
      nil ->
        vote = Reactions.get_vote_by(%{comment_id: comment_id, user_id: user_id})
        Map.put(new_votes, comment_id, vote)
      _ ->
        new_votes
    end
  end

  defp todays_date() do
    DateTime.utc_now |> DateTime.to_string |> String.slice(0, 10)
  end
  defp yesterdays_date() do
    DateTime.utc_now |> Timex.shift(hours: -24) |> DateTime.to_string |> String.slice(0, 10)
  end
  defp this_weeks_date() do
    Date.utc_today |> Date.beginning_of_week |> Date.to_string
  end
  defp weeks_date(date) do
    Board.date_string_to_date(date) |> Date.beginning_of_week |> Date.to_string
  end

end
