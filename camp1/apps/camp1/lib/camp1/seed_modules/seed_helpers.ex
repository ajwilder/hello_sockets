defmodule Camp1.SeedHelpers do
  alias Camp1.{Topics, Public}
  def insert_camp_check_content(map = %{original_content: original_content, slug: slug}) do
    camp = Public.get_camp_by(original_content: original_content)
    cond do
      camp ->
        insert_exposed_slug(slug, camp.id)
      true ->
        {:ok, camp} = Public.create_camp(map)
        insert_exposed_slug(slug, camp.id)
    end
  end

  def insert_camp_check_content(map = %{original_content: original_content}) do
    camp = Public.get_camp_by(original_content: original_content)
    IO.inspect map
    cond do
      camp ->
        :ok
      true ->
        {:ok, _camp} = Public.create_camp(map)
    end
  end

  def insert_exposed_slug(slug, camp_id) do
    :ok
  end

  def insert_camp_based_on_parent_content(map = %{parent_content: parent_content}) do
    parent = Public.get_camp_by(original_content: parent_content)
    cond do
      parent ->
        %{id: parent_id} = parent
        map
        |> Map.put(:camp_parents, [%{parent_id: parent_id}])
        |> insert_camp_check_content()
      true ->
        raise("This seed camp needs to have a parent: #{parent_content}")
    end
  end

  def insert_movie_camp(title) do
    insert_camp_based_on_parent_content(
      %{
        type: "creation",
        parent_content: "Movies",
        status: "live",
        original_content: title
      }
    )
  end

  def trim_and_strip(str) do
    str
    |> String.trim
    |> String.replace("\uFEFF","")
  end

  def create_or_find_subject(content, parent_id) do
    subject = Topics.get_subject_by(%{content: content})
    case subject do
      %{id: id} ->
        id
      nil ->
        {:ok, subject} = Topics.create_subject(
          %{
            parent_id: parent_id,
            content: content
          }
        )
        subject.id
    end
  end

  def create_or_find_camp(content, subject_id, opponent_id) do
    camp = Public.get_camp_by(%{current_content: content})
    case camp do
      nil ->
        case opponent_id do
          nil ->
            {:ok, camp} = Public.create_camp(%{
                type: "notion",
                subject_id: subject_id,
                status: "live",
                original_content: content
              })
            camp
          opponent_id ->
            attrs = %{
                type: "notion",
                subject_id: subject_id,
                status: "live",
                original_content: content
              }
            {:ok, %{camp: camp}} = Public.create_camp_with_opponent(attrs, opponent_id)
            camp
        end
      camp ->
        camp
    end
  end

end
