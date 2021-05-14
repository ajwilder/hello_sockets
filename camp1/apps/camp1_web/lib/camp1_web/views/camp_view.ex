defmodule Camp1Web.CampView do
  use Camp1Web, :view

  def limit_title(title) do
    String.slice(title, 0..140)
  end

  def limit_parent(title) do
    l = String.length title
    case l do
      l when l < 40 ->
        title
      _ ->
        String.slice(title, 0..40) <> "..."
    end
  end

  def date_string(datetime) do
    Date.to_string DateTime.to_date datetime
  end

  def select_camp_template(nil), do: "users/_expand_overview.html"
  def select_camp_template("overview"), do: "users/_expand_overview.html"
  def select_camp_template("board"), do: "users/_expand_board.html"
  def select_camp_template("discussion"), do: "users/_expand_discussion.html"
  def select_camp_template("manage"), do: "users/_expand_manage.html"
  def select_camp_template("manifesto"), do: "users/_expand_manifesto.html"


  def select_overview_template(sub_menu, subsub_menu)
  def select_overview_template(nil, _subsub_menu), do: "users/_user_overview.html"
  def select_overview_template("activity", _subsub_menu), do: "users/_user_overview.html"
  def select_overview_template("subcamps", _subsub_menu), do: "users/subcamps/_user_subcamps.html"
  def select_overview_template("opponents", _subsub_menu), do: "users/_user_opponents.html"
  def select_overview_template("compare", _subsub_menu), do: "users/_user_compare.html"

  def select_board_template(sub_menu, subsub_menu)
  def select_board_template(nil, nil), do: "users/board/_user_board.html"
  def select_board_template("posts", nil), do: "users/board/_user_board.html"
  def select_board_template("posts", _subsub_menu), do: "users/board/_user_board_highlighted_post.html"
  def select_board_template("images", nil), do: "users/board/_user_board.html"
  def select_board_template("images", _subsub_menu), do: "users/board/_user_board_highlighted_post.html"
  def select_board_template("documents", nil), do: "users/board/_user_board.html"
  def select_board_template("documents", _subsub_menu), do: "users/board/_user_board_highlighted_post.html"

  def select_discussion_template(sub_menu, subsub_menu)
  def select_discussion_template(nil, _subsub_menu), do: "users/_user_chat_room.html"
  def select_discussion_template("text", _subsub_menu), do: "users/_user_chat_room.html"
  def select_discussion_template("audio", _subsub_menu), do: "users/_user_audio_room.html"

  def select_manifesto_template(sub_menu, subsub_menu)
  def select_manifesto_template(nil, _subsub_menu), do: "users/_user_manifesto.html"
  def select_manifesto_template("manifesto", _subsub_menu), do: "users/_user_manifesto.html"
  def select_manifesto_template("lexicon", _subsub_menu), do: "users/_user_lexicon.html"

  def get_agree_button_classes(1), do: "old_vote voted"
  def get_agree_button_classes(0), do: "old_vote"
  def get_agree_button_classes(-1), do: "old_vote disabled-button"
  def get_agree_button_classes(_), do: ""

  def get_disagree_button_classes(-1), do: "old_vote voted"
  def get_disagree_button_classes(0), do: "old_vote"
  def get_disagree_button_classes(1), do: "old_vote disabled-button"
  def get_disagree_button_classes(_), do: ""


  def parse_manifesto_vote_data(nil), do: nil
  def parse_manifesto_vote_data({_, 0}), do: nil
  def parse_manifesto_vote_data({_, value}), do: value

end
