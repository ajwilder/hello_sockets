defmodule Camp1Web.CommentController do
  use Camp1Web, :controller
  alias Camp1.{Board, UserServer}
  alias Camp1.Public.Image


  def create_post(conn, %{"id" => id, "comment" => %{"content" => content, "parent_id" => parent_id}}) do
    user_id = conn.assigns[:current_user].id
    id = String.to_integer(id)
    comment_params = %{
      user_id: user_id,
      camp_id: id,
      content: content,
      parent_id: parent_id
    }

    {:ok, %{comment: comment, vote: _vote}} = Board.create_comment(comment_params)
    Board.add_new_comment_comment_to_server(comment)
    UserServer.put_new_vote(user_id, id, comment.id, 1, false)
    redirect(conn, to: "/camp/#{id}?1=board&2=posts&3=#{parent_id}")
  end

  def create_post(conn, %{"id" => id, "comment" => %{"content" => content}}) do
    user_id = conn.assigns[:current_user].id
    id = String.to_integer(id)
    comment_params = %{
      user_id: user_id,
      camp_id: id,
      content: content
    }
    {:ok, %{comment: comment, vote: _vote}} = Board.create_comment(comment_params)
    Board.add_new_comment_to_server(comment)
    UserServer.put_new_vote(user_id, id, comment.id, 1, false)
    redirect(conn, to: "/camp/#{id}?1=board&2=posts&3=#{comment.id}")
  end

  # def create_image(conn, %{"id" => id, "comment" => %{"content" => content, "parent_id" => parent_id}}) do
  #   user_id = conn.assigns[:current_user].id
  #   id = String.to_integer(id)
  #   comment_params = %{
  #     user_id: user_id,
  #     camp_id: id,
  #     content: content,
  #     parent_id: parent_id
  #   }
  #
  #   {:ok, %{comment: comment, vote: _vote}} = Board.create_comment(comment_params)
  #   Board.add_new_comment_comment_to_server(comment)
  #   UserServer.put_new_vote(user_id, id, comment.id, 1, false)
  #   redirect(conn, to: "/camp/#{id}?1=board&2=images&3=#{parent_id}")
  # end

  def create_image(conn, %{"id" => id, "comment" => %{"content" => content, "upload" => %Plug.Upload{}=upload}}) do
    user_id = conn.assigns[:current_user].id
    id = String.to_integer(id)
    comment_params = %{
      user_id: user_id,
      camp_id: id,
      content: content
    }
    {:ok, %{comment: _comment, vote: _vote, image: _image, image_relationship: _image_relationship, updated_comment: comment}} = Board.create_comment_with_image(comment_params, upload)
    Board.add_new_comment_to_server(comment)
    UserServer.put_new_vote(user_id, id, comment.id, 1, false)
    redirect(conn, to: "/camp/#{id}?1=board&2=images&3=#{comment.id}")
  end

  def create_document(conn, %{"id" => id, "comment" => %{"content" => content, "upload" => %Plug.Upload{}=upload}}) do
    user_id = conn.assigns[:current_user].id
    id = String.to_integer(id)
    comment_params = %{
      user_id: user_id,
      camp_id: id,
      content: content
    }
    {:ok, %{comment: _comment, vote: _vote, document: _image, document_relationship: _image_relationship, updated_comment: comment}} = Board.create_comment_with_document(comment_params, upload)
    Board.add_new_comment_to_server(comment)
    UserServer.put_new_vote(user_id, id, comment.id, 1, false)
    redirect(conn, to: "/camp/#{id}?1=board&2=images&3=#{comment.id}")
  end


  def thumbnail(conn, %{"upload_id" => id}) do
    thumb_path = Image.thumbnail_path(id)

    conn
    |> put_resp_content_type("image/jpeg")
    |> send_file(200, thumb_path)

  end

end
