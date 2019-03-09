defmodule CustomDataGen do
  use ExUnitProperties

  def string_gen do
    ExUnitProperties.gen all string <-
                               StreamData.string(Enum.concat([?a..?z, ?A..?Z, ?0..?9, [?-]])) do
      string
    end
  end

  def id_gen(initial) do
    ExUnitProperties.gen all string <- string_gen() do
      initial <> string
    end
  end

  def url_gen do
    ExUnitProperties.gen all string <- string_gen() do
      "www." <> string <> ".com"
    end
  end

  @presence_values ["active", "away"]

  def presence_gen do
    ExUnitProperties.gen all presence <- StreamData.member_of(@presence_values) do
      presence
    end
  end

  @custom_maps [%{foo: :bar}, %{test: :tested}]

  def map_gen do
    ExUnitProperties.gen all map <- member_of(@custom_maps) do
      map
    end
  end

  def list_of_user_ids_gen do
    ExUnitProperties.gen all n <- StreamData.integer(0..10) do
      Enum.take(id_gen("U"), n)
    end
  end
end
