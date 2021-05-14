defmodule Camp1.Public.Image do
  use Ecto.Schema
  import Ecto.Changeset


  schema "images" do
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
    Application.get_env(:camp1, :image_uploads_directory)
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

  def mogrify_thumbnail(src_path, dst_path) do
    try do
      Mogrify.open(src_path)
      |> Mogrify.resize_to_limit("300x300")
      |> Mogrify.save(path: dst_path)
    rescue
      File.Error -> {:error, :invalid_src_path}
      error -> {:error, error}
    else
      _image -> {:ok, dst_path}
    end
  end

end
