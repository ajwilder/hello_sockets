import Camp1.SeedHelpers
alias Camp1.{Public, SeedUsers, SeedRatings, SeedCamps}



# "apps/camp1/priv/repo/seed_data/movies.csv"
# |> File.stream!
# |> CSV.decode
# |> Enum.each(fn {:ok, [movie | _]} ->
#   movie
#   |> trim_and_strip()
#   |> insert_movie_camp()
# end)


"apps/camp1/priv/repo/seed_data/seed_topics.csv"
|> File.stream!
|> CSV.decode
|> Enum.each(fn {:ok, row} ->
  case Enum.at(row, 3) do
    "" ->
      :ok
    nil ->
      :ok
    _ ->
      subject1_content = trim_and_strip(Enum.at(row, 0))
      subject2_content = trim_and_strip(Enum.at(row, 1))
      IO.inspect {subject1_content, subject2_content}

      subject1_id = create_or_find_subject(subject1_content, nil)
      subject2_id = create_or_find_subject(subject2_content, subject1_id)

      camp1_content = trim_and_strip(Enum.at(row, 2))
      camp2_content = trim_and_strip(Enum.at(row, 3))

      camp1 = create_or_find_camp(camp1_content, subject2_id, nil)
      camp2 = create_or_find_camp(camp2_content, subject2_id, camp1.id)

      {:ok, _relationship} = Public.create_camp_opponent_relationship(
        %{
          camp_id: camp1.id,
          opponent_id: camp2.id
        }
      )
  end
end)

# "apps/camp1/priv/repo/seed_data/top_uk_books_all_time.csv"
# |> File.stream!
# |> CSV.decode
# |> Enum.each(&(IO.inspect(&1 |> elem(1))))


SeedUsers.seed_n_users(100)
SeedUsers.seed_contacts
SeedCamps.add_some_fake_opponents(3)
SeedCamps.add_n_reasons_to_existing_camps(2)
SeedCamps.add_n_children_to_existing_camps(1)
SeedRatings.add_ratings_to_camps()





# seed some chats

user_id = 7

Enum.each(1..200, fn _i ->
  attrs = %{
    name:  FakerElixir.Lorem.words(6)
  }
  user_list = [{user_id, "Otha"}, {Enum.random(1..119), FakerElixir.Name.first_name}]
  Camp1.Private.create_private_chat_with_users(attrs, user_list)
end)
