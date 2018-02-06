defmodule ExLoader.Adapter do
  @moduledoc false

  @doc """
  Verify if the given file is valid and accessible
  """
  @callback valid?(String.t()) :: boolean

  @doc """
  get the content of the file
  """
  @callback get_content(String.t()) :: {:ok, binary} | {:error, term}
end
