defmodule Camp1.SlugsTest do
  use Camp1.DataCase

  alias Camp1.Slugs

  describe "exposed_slugs" do
    alias Camp1.Slugs.ExposedSlug

    @valid_attrs %{slug: "some slug"}
    @update_attrs %{slug: "some updated slug"}
    @invalid_attrs %{slug: nil}

    def exposed_slug_fixture(attrs \\ %{}) do
      {:ok, exposed_slug} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Slugs.create_exposed_slug()

      exposed_slug
    end

    test "list_exposed_slugs/0 returns all exposed_slugs" do
      exposed_slug = exposed_slug_fixture()
      assert Slugs.list_exposed_slugs() == [exposed_slug]
    end

    test "get_exposed_slug!/1 returns the exposed_slug with given id" do
      exposed_slug = exposed_slug_fixture()
      assert Slugs.get_exposed_slug!(exposed_slug.id) == exposed_slug
    end

    test "create_exposed_slug/1 with valid data creates a exposed_slug" do
      assert {:ok, %ExposedSlug{} = exposed_slug} = Slugs.create_exposed_slug(@valid_attrs)
      assert exposed_slug.slug == "some slug"
    end

    test "create_exposed_slug/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Slugs.create_exposed_slug(@invalid_attrs)
    end

    test "update_exposed_slug/2 with valid data updates the exposed_slug" do
      exposed_slug = exposed_slug_fixture()
      assert {:ok, %ExposedSlug{} = exposed_slug} = Slugs.update_exposed_slug(exposed_slug, @update_attrs)
      assert exposed_slug.slug == "some updated slug"
    end

    test "update_exposed_slug/2 with invalid data returns error changeset" do
      exposed_slug = exposed_slug_fixture()
      assert {:error, %Ecto.Changeset{}} = Slugs.update_exposed_slug(exposed_slug, @invalid_attrs)
      assert exposed_slug == Slugs.get_exposed_slug!(exposed_slug.id)
    end

    test "delete_exposed_slug/1 deletes the exposed_slug" do
      exposed_slug = exposed_slug_fixture()
      assert {:ok, %ExposedSlug{}} = Slugs.delete_exposed_slug(exposed_slug)
      assert_raise Ecto.NoResultsError, fn -> Slugs.get_exposed_slug!(exposed_slug.id) end
    end

    test "change_exposed_slug/1 returns a exposed_slug changeset" do
      exposed_slug = exposed_slug_fixture()
      assert %Ecto.Changeset{} = Slugs.change_exposed_slug(exposed_slug)
    end
  end
end
