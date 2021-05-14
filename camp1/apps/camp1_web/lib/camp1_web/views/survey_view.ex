defmodule Camp1Web.SurveyView do
  use Camp1Web, :view

  def prompts_by_type(type) do
    case type do
      :creation ->
        %{
          rating_prompts: ["Hate it", "Dislike it", "It's OK", "Like it", "Love it"],
          dismissal_prompts: [{"Don't Care", 0}, {"Don't know", 6}]
        }
      :notion ->
        %{
          rating_prompts: ["Disagree", "Unlikely", "Maybe", "Probably", "Agree"],
          dismissal_prompts: [{"Don't Care", 0}]
        }
      :question ->
        %{
          rating_prompts: ["Disagree", "Unlikely", "Maybe", "Probably", "Agree"],
          dismissal_prompts: []
        }
    end
  end

  def result_display(type, rating) do
    case type do
      :creation ->
        get_creation_result_display(rating)
      :notion ->
        get_notion_result_display(rating)
      :type ->
        get_notion_result_display(rating)
    end
  end

  defp get_notion_result_display(rating) do
    case rating do
      0 ->
        "don't care"
      1 ->
        "disagree"
      2 ->
        "say unlikely"
      3 ->
        "say maybe"
      4 ->
        "say probably"
      5 ->
        "agree"
    end
  end

  defp get_creation_result_display(rating) do
    case rating do
      0 ->
        "don't care"
      1 ->
        "hate this"
      2 ->
        "dislike this"
      3 ->
        "say it's OK"
      4 ->
        "like this"
      5 ->
        "love this"
    end

  end

  def percentage(num, den) do
    case num do
      0 ->
        0.0
      num ->
        num / den * 100
        |> Decimal.from_float()
        |> Decimal.round(1)
      end
  end

end
