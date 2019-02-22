defmodule CustomDataGen do
  use ExUnitProperties

  def custom_id_gen(initial) do
    ExUnitProperties.gen all string <- StreamData.string(:ascii) do
      initial <> string
    end
  end

  def custom_url_gen() do
    ExUnitProperties.gen all string <- StreamData.string(:ascii) do
      "www." <> string <> ".com"
    end
  end
end
