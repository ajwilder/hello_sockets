defmodule Camp1.TopicsTest do
  use Camp1.DataCase

  alias Camp1.Topics

  describe "posts" do
    alias Camp1.Topics.Post

    @valid_attrs %{current_content: "some current_content", original_content: "some original_content", parent_id: 42, status: "some status", type: "some type"}
    @update_attrs %{current_content: "some updated current_content", original_content: "some updated original_content", parent_id: 43, status: "some updated status", type: "some updated type"}
    @invalid_attrs %{current_content: nil, original_content: nil, parent_id: nil, status: nil, type: nil}

    def post_fixture(attrs \\ %{}) do
      {:ok, post} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Topics.create_post()

      post
    end

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Topics.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Topics.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      assert {:ok, %Post{} = post} = Topics.create_post(@valid_attrs)
      assert post.current_content == "some current_content"
      assert post.original_content == "some original_content"
      assert post.parent_id == 42
      assert post.status == "some status"
      assert post.type == "some type"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Topics.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      assert {:ok, %Post{} = post} = Topics.update_post(post, @update_attrs)
      assert post.current_content == "some updated current_content"
      assert post.original_content == "some updated original_content"
      assert post.parent_id == 43
      assert post.status == "some updated status"
      assert post.type == "some updated type"
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Topics.update_post(post, @invalid_attrs)
      assert post == Topics.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Topics.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Topics.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Topics.change_post(post)
    end
  end

  describe "subjects" do
    alias Camp1.Topics.Subject

    @valid_attrs %{content: "some content"}
    @update_attrs %{content: "some updated content"}
    @invalid_attrs %{content: nil}

    def subject_fixture(attrs \\ %{}) do
      {:ok, subject} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Topics.create_subject()

      subject
    end

    test "list_subjects/0 returns all subjects" do
      subject = subject_fixture()
      assert Topics.list_subjects() == [subject]
    end

    test "get_subject!/1 returns the subject with given id" do
      subject = subject_fixture()
      assert Topics.get_subject!(subject.id) == subject
    end

    test "create_subject/1 with valid data creates a subject" do
      assert {:ok, %Subject{} = subject} = Topics.create_subject(@valid_attrs)
      assert subject.content == "some content"
    end

    test "create_subject/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Topics.create_subject(@invalid_attrs)
    end

    test "update_subject/2 with valid data updates the subject" do
      subject = subject_fixture()
      assert {:ok, %Subject{} = subject} = Topics.update_subject(subject, @update_attrs)
      assert subject.content == "some updated content"
    end

    test "update_subject/2 with invalid data returns error changeset" do
      subject = subject_fixture()
      assert {:error, %Ecto.Changeset{}} = Topics.update_subject(subject, @invalid_attrs)
      assert subject == Topics.get_subject!(subject.id)
    end

    test "delete_subject/1 deletes the subject" do
      subject = subject_fixture()
      assert {:ok, %Subject{}} = Topics.delete_subject(subject)
      assert_raise Ecto.NoResultsError, fn -> Topics.get_subject!(subject.id) end
    end

    test "change_subject/1 returns a subject changeset" do
      subject = subject_fixture()
      assert %Ecto.Changeset{} = Topics.change_subject(subject)
    end
  end
end
