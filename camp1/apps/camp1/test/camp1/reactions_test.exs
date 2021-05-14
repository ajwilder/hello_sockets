defmodule Camp1.ReactionsTest do
  use Camp1.DataCase

  alias Camp1.Reactions

  describe "ratings" do
    alias Camp1.Reactions.Rating

    @valid_attrs %{value: 42}
    @update_attrs %{value: 43}
    @invalid_attrs %{value: nil}

    def rating_fixture(attrs \\ %{}) do
      {:ok, rating} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Reactions.create_rating()

      rating
    end

    test "list_ratings/0 returns all ratings" do
      rating = rating_fixture()
      assert Reactions.list_ratings() == [rating]
    end

    test "get_rating!/1 returns the rating with given id" do
      rating = rating_fixture()
      assert Reactions.get_rating!(rating.id) == rating
    end

    test "create_rating/1 with valid data creates a rating" do
      assert {:ok, %Rating{} = rating} = Reactions.create_rating(@valid_attrs)
      assert rating.value == 42
    end

    test "create_rating/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reactions.create_rating(@invalid_attrs)
    end

    test "update_rating/2 with valid data updates the rating" do
      rating = rating_fixture()
      assert {:ok, %Rating{} = rating} = Reactions.update_rating(rating, @update_attrs)
      assert rating.value == 43
    end

    test "update_rating/2 with invalid data returns error changeset" do
      rating = rating_fixture()
      assert {:error, %Ecto.Changeset{}} = Reactions.update_rating(rating, @invalid_attrs)
      assert rating == Reactions.get_rating!(rating.id)
    end

    test "delete_rating/1 deletes the rating" do
      rating = rating_fixture()
      assert {:ok, %Rating{}} = Reactions.delete_rating(rating)
      assert_raise Ecto.NoResultsError, fn -> Reactions.get_rating!(rating.id) end
    end

    test "change_rating/1 returns a rating changeset" do
      rating = rating_fixture()
      assert %Ecto.Changeset{} = Reactions.change_rating(rating)
    end
  end
end
