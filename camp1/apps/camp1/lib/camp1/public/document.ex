defmodule Camp1.Public.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Board.Comment
  import Ecto.Query, warn: false
  alias Camp1.Repo

  schema "documents" do
    field :hash, :string
    field :size, :integer

    timestamps()
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:size, :hash])
    |> validate_required([:size, :hash])
    |> validate_number(:size, greater_than: 0)
    |> validate_length(:hash, is: 64)
  end

  def local_path(id) do
    [upload_directory(), "#{id}"]
    |> Path.join()
  end

  def upload_directory do
    Application.get_env(:camp1, :document_uploads_directory)
  end

  def thumbnail_path(id) do
    [upload_directory(), "thumb-#{id}.jpg"]
    |> Path.join()
  end

  def create_thumbnail(%__MODULE__{} = image) do
    original_path = local_path(image.id)
    thumb_path = thumbnail_path(image.id)
    {:ok, _} = mogrify_thumbnail(original_path, thumb_path)
  end

  def mogrify_thumbnail(src_path, thumb_path) do
    args = ["-density", "300", "-resize",
            "300x300","#{src_path}[0]",
            thumb_path]

    case System.cmd("convert", args, stderr_to_stdout: true) do
      {_, 0} -> {:ok, thumb_path}
      {reason, _} -> {:error, reason}
    end
  end

  def get_document_content(camp_id, document_id) do
    query_document_content(camp_id, document_id)
    |> Repo.all
    |> List.first
  end

  defp query_document_content(camp_id, document_id) do
    from c in Comment,
      where: c.camp_id == ^camp_id,
      where: c.document_id == ^ document_id,
      select: c.content
  end
end
