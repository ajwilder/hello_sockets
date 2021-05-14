defmodule Camp1Web.CampController do
  use Camp1Web, :controller
  alias Camp1.{CampServer, UserServer, UserHome, Board, Topics, CampHome, PublicChat, Audio}
  alias Camp1.Manifesto.ManifestoServer
  alias Camp1.Board.BoardServer
  alias Camp1Web.UserAuth

  plug :put_layout, "guest.html"

  def guest_explore_camp(conn, params = %{"id" => id}) do
    id = String.to_integer id
    camp = CampServer.get_camp_for_home_page(id)
    expand = Map.get(params, "1")
    sub_menu = Map.get(params, "2")
    subsub_menu = Map.get(params, "3")
    changeset = Board.Comment.changeset(%Board.Comment{}, %{})
    data =
      get_expanded(expand, id, conn.assigns[:current_user].id, sub_menu, subsub_menu)
      |> Map.put(:camp_id, id)
    case camp do
      nil ->
        redirect(conn, to: "/")
      camp ->
        conn
        |> assign(:expand, expand)
        |> assign(:sub_menu, sub_menu)
        |> assign(:subsub_menu, subsub_menu)
        |> assign(:changeset, changeset)
        |> assign(:channel, :camp)
        |> assign(:camp, camp)
        |> assign(:camp_id, id)
        |> assign(:data, data)
        |> render_guest_or_user_template(id)
    end
  end

  def user_explore_camp(conn, params = %{"id" => id}) do
    id = String.to_integer id
    camp = CampServer.get_camp_for_home_page(id)
    expand = Map.get(params, "1")
    sub_menu = Map.get(params, "2")
    subsub_menu = Map.get(params, "3")
    changeset = Board.Comment.changeset(%Board.Comment{}, %{})
    case conn.assigns[:current_user] do
      nil ->
        UserAuth.log_out_user(conn)
      current_user ->
        data =
          get_expanded(expand, id, current_user.id, sub_menu, subsub_menu)
          |> Map.put(:camp_id, id)
        case camp do
          nil ->
            redirect(conn, to: "/")
          camp ->
            conn
            |> assign(:expand, expand)
            |> assign(:sub_menu, sub_menu)
            |> assign(:subsub_menu, subsub_menu)
            |> assign(:changeset, changeset)
            |> assign(:channel, :camp)
            |> assign(:camp, camp)
            |> assign(:camp_id, id)
            |> assign(:data, data)
            |> render_guest_or_user_template(id)
        end
    end
  end


  defp render_guest_or_user_template(conn, camp_id) do
    if user = conn.assigns[:current_user] do
      agreement = UserServer.get_user_agreement(user.id, camp_id)
      store_user_views(agreement, user.id, conn.assigns[:camp])
      conn
      # |> assign(:user_token, token)
      |> assign(:agreement, agreement)
      |> put_layout("user.html")
      |> render("camp_home.html")
    else
      conn
      |> render("guest_camp.html")
    end
  end



  defp get_expanded(nil, _camp_id, _user_id, nil, nil) do
    %{}
  end
  defp get_expanded("overview", _camp_id, _user_id, nil, nil) do
    %{}
  end
  defp get_expanded("overview", _camp_id, _user_id, "activity", nil) do
    %{}
  end
  defp get_expanded("overview", camp_id, _user_id, "subcamps", nil) do
    %{
      camps: CampServer.get_children(camp_id, :newest, 0)
    }
  end
  defp get_expanded("overview", camp_id, _user_id, "opponents", nil) do
    top_opponents = CampServer.get_opponents(camp_id, :biggest, 0)
    %{
      top_opponents: top_opponents,
      opponent_view: CampHome.get_opponent_view(camp_id, List.first(top_opponents)[:id]),
    }
  end
  defp get_expanded("overview", camp_id, user_id, "compare", nil) do
    %{
      compare: UserServer.UserCompare.compare_user_to_camp(user_id, camp_id),
      subject_names: Topics.TopicsServer.get_top_subject_names,
      compare_type: :camp
    }
  end
  defp get_expanded("board", camp_id, user_id, nil, nil) do
    %{
      next_page: 1,
      board_type: :posts,
      date: nil,
      order_by: :recent,
      posts: BoardServer.get_posts(camp_id, :posts, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
  end
  defp get_expanded("board", camp_id, user_id, "posts", nil) do
    %{
      next_page: 1,
      board_type: :posts,
      date: nil,
      order_by: :recent,
      posts: BoardServer.get_posts(camp_id, :posts, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
  end
  defp get_expanded("board", camp_id, user_id, "posts", comment_id) do
    %{
      post: BoardServer.get_post(camp_id, comment_id),
      comments: BoardServer.get_comments(comment_id, camp_id, 0),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id),
      board_type: "posts"
    }
  end
  defp get_expanded("board", camp_id, user_id, "images", nil) do
    %{
      next_page: 1,
      board_type: :images,
      date: nil,
      order_by: :recent,
      posts: BoardServer.get_posts(camp_id, :images, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
  end
  defp get_expanded("board", camp_id, user_id, "images", comment_id) do
    %{
      post: BoardServer.get_post(camp_id, comment_id),
      comments: BoardServer.get_comments(comment_id, camp_id, 0),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id),
      board_type: "images"
    }
  end
  defp get_expanded("board", camp_id, user_id, "documents", nil) do
    %{
      next_page: 1,
      board_type: :documents,
      date: nil,
      order_by: :recent,
      posts: BoardServer.get_posts(camp_id, :documents, :recent, 0, nil),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id)
    }
  end
  defp get_expanded("board", camp_id, user_id, "documents", comment_id) do
    %{
      post: BoardServer.get_post(camp_id, comment_id),
      comments: BoardServer.get_comments(comment_id, camp_id, 0),
      user_vote_data: UserServer.get_vote_data(user_id, camp_id),
      board_type: "documents"
    }
  end
  # defp get_expanded("board", camp_id, user_id, "reasons", nil) do
  #   %{
  #     data: Board.get_initial_posts(camp_id, %{include_images?: true}),
  #     user_vote_data: UserServer.get_vote_data(user_id, camp_id)
  #   }
  # end
  # defp get_expanded("board", camp_id, user_id, "reasons", comment_id) do
  #   %{
  #     data: Board.get_initial_posts(camp_id, %{comment_id: comment_id, include_images?: true}),
  #     user_vote_data: UserServer.get_vote_data(user_id, camp_id)
  #   }
  # end
  defp get_expanded("discussion", camp_id, _user_id, nil, nil) do
    %{
      messages: PublicChat.get_recent_messages(camp_id, 0)
    }
  end
  defp get_expanded("discussion", camp_id, _user_id, "text", nil) do
    %{
      messages: PublicChat.get_recent_messages(camp_id, 0)
    }
  end
  defp get_expanded("discussion", camp_id, _user_id, "audio", nil) do
    %{
      audio_status: Audio.get_camp_channel_status(camp_id),
      camp_id: camp_id,

    }
  end
  defp get_expanded("manage", _camp_id, _user_id, nil, _subsub_menu) do
    %{}
  end
  defp get_expanded("manage", _camp_id, _user_id, "leave", _subsub_menu) do
    %{}
  end
  defp get_expanded("manage", _camp_id, _user_id, "settings", _subsub_menu) do
    %{}
  end
  defp get_expanded("manifesto", camp_id, user_id, nil, nil) do
    %{
      proposed: ManifestoServer.get_proposed(camp_id),
      manifesto: ManifestoServer.get_live_manifesto(camp_id),
      history: ManifestoServer.get_history(camp_id),
      votes: UserServer.get_camp_manifesto_votes(user_id, camp_id)
    }
  end
  defp get_expanded("manifesto", camp_id, user_id, "manifesto", nil) do
    %{
      proposed: ManifestoServer.get_proposed(camp_id),
      manifesto: ManifestoServer.get_live_manifesto(camp_id),
      history: ManifestoServer.get_history(camp_id),
      votes: UserServer.get_camp_manifesto_votes(user_id, camp_id)
    }
  end
  defp get_expanded("manifesto", _camp_id, _user_id, "lexicon", nil) do
    %{}
  end


  defp store_user_views(agreement, user_id, camp) do
    case agreement do
      true ->
        spawn(UserHome, :store_recent_camp_view, [user_id, camp, :joined])
      _ ->
        spawn(UserHome, :store_recent_camp_view, [user_id, camp, :unjoined])
    end
  end




end
