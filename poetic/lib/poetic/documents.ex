defmodule Poetic.Documents do
  import Ecto.Query, warn: false

  alias Poetic.Repo
  alias Poetic.Documents.Upload

  def create_upload_from_plug_upload(%Plug.Upload{
    filename: filename,
    path: tmp_path,
    content_type: content_type
  }) do

    hash =
      File.stream!(tmp_path, [], 2048)
      |> Upload.sha256()

    with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
      {:ok, upload} <-
        %Upload{}
        |> Upload.changeset(%{
          filename: filename, content_type: content_type,
          hash: hash, size: size })
        |> Repo.insert(),

      :ok <- File.cp(
          tmp_path,
          Upload.local_path(upload.id, filename)
       ),

       {:ok, upload} <-
         Upload.create_thumbnail(upload) |> Repo.update()

    do

      {:ok, upload}

    else

      {:error, reason}=error -> error

    end

  end

  def list_uploads do
    Repo.all(Upload)
  end

  def get_upload!(id) do
    Upload
    |> Repo.get!(id)
  end

end
