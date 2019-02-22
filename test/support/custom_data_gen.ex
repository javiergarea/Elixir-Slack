defmodule CustomDataGen do
  use ExUnitProperties

  def custom_id_gen(first) do
    ExUnitProperties.gen all string <- StreamData.string(:ascii) do
      first <> string
    end
  end

  def custom_url_gen() do
    ExUnitProperties.gen all string <- StreamData.string(:ascii) do
      "www." <> string <> ".com"
    end
  end
end
