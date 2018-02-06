defmodule ExLoader.Adapters.Http do
  @moduledoc false

  @behaviour ExLoader.Adapter

  def valid?(src) do
    {:ok, %HTTPoison.Response{status_code: code}} = HTTPoison.head(src)

    case code do
      200 -> true
      _ -> false
    end
  end

  def get_content(src) do
    {:ok, %HTTPoison.Response{status_code: code, body: body}} = HTTPoison.get(src)

    case code do
      200 ->
        {:ok, body}

      _ ->
        {:error, %{msg: "cannot read file #{src}. Reason: #{inspect(code)}", reason: code}}
    end
  end
end
