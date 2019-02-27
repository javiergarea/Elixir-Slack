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

  def map_gen(_n) do
    ExUnitProperties.gen all map <-
                               member_of([%{foo: :bar}]) do
      map
    end
  end

  def list_of_string_gen do
    ExUnitProperties.gen all map <-
                               member_of([["%{foo: :bar}"], [], [[[]]]]) do
      map
    end
  end
end
