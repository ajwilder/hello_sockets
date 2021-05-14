alias TribeSmith.Repo
alias TribeSmith.Accounts.User
alias TribeSmith.Topics.Post
alias TribeSmith.{Topics, Accounts}

defmodule SeedFunctions do
  def insert_post_check_content(map = %{original_content: o}) do
    cond  do
      _post = Topics.get_post_by(original_content: o) ->
        nil
      true ->
        Repo.insert!(
          %Post{
            type: map[:type],
            parent_id: map[:parent_id],
            status: map[:status],
            current_content: map[:current_content],
            original_content: map[:original_content],
          }
        )
    end
  end

end

users = [
  %{
    email: "wilderalan@gmail.com",
    points: 0,
    status: "1"
  },
  %{
    email: "andrewaghapour@gmail.com",
    points: 0,
    status: "1"
  },
  %{
    email: "w.jewett711@gmail.com",
    points: 0,
    status: "1"
  },
]

top_topics = [
  %{
    type: "creation",
    parent_id: 0,
    status: "live",
    current_content: "All",
    original_content: "All"
  },
  %{
    type: "creation",
    parent_id: 1,
    status: "live",
    current_content: "Movies",
    original_content: "Movies"
  },
  %{
    type: "creation",
    parent_id: 1,
    status: "live",
    current_content: "Ideas",
    original_content: "Ideas"
  },
  %{
    type: "creation",
    parent_id: 1,
    status: "live",
    current_content: "Politics",
    original_content: "Politics"
  }
]
seed_posts = [
  %{
    type: "question",
    parent: "Ideas",
    status: "live",
    original_content: "Do you believe in God?"
  },
  %{
    type: "notion",
    parent: "Ideas",
    status: "live",
    original_content: ""
  }
]

top_topics
|> Enum.each(SeedFunctions.insert_post_check_content())
