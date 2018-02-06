defmodule ExLoader.Adapters.File do
  @moduledoc false

  @behaviour ExLoader.Adapter

  def valid?(src), do: File.exists?(src)

  def get_content(src) do
    case File.read(src) do
      {:ok, bin} ->
        {:ok, bin}

      {:error, reason} ->
        {:error, %{msg: "cannot read file #{src}. Reason: #{inspect(reason)}", reason: reason}}
    end
  end
end
