defmodule ExLoader do
  @moduledoc """
  Documentation for ExLoader.
  """

  @beam_ext ".beam"

  @doc """
  load a beam file to a node
  """
  @spec load_module(String.t()) :: {:ok, atom} | {:error, term}
  def load_module(beam_file), do: load_module(beam_file, node())

  def load_module(beam_file, remote_node) do
    with {:ok, dst} <- ExLoader.File.copy(remote_node, beam_file),
         {:ok, module} <- load(remote_node, dst) do
      {:ok, module}
    else
      err -> err
    end
  end

  def load_apps(tarball, apps), do: load_apps(tarball, apps, node())

  def load_apps(tarball, apps, remote_node) do
    with {:ok, dst} <- ExLoader.File.copy(remote_node, tarball),
         :ok <- ExLoader.File.uncompress(dst) do
      ExLoader.Release.load(Path.dirname(dst), apps)
    else
      err -> err
    end
  end

  def load_release(tarball), do: load_release(tarball, node())

  def load_release(tarball, remote_node) do
    load_apps(tarball, nil, remote_node)
  end

  defp load(remote_node, dst) do
    # :code.load_abs requires a file without extentions. weird.
    file = String.trim_trailing(dst, @beam_ext)
    result = :rpc.call(remote_node, :code, :load_abs, [to_charlist(file)])

    case result do
      {:module, module} ->
        {:ok, module}

      {:error, reason} ->
        {:error,
         %{
           msg:
             "Cannot load the file from remote node #{inspect(remote_node)}. Reason: #{
               inspect(reason)
             }",
           reason: reason
         }}
    end
  end
end
