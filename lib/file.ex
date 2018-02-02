defmodule ExLoader.File do
  @moduledoc """
  copy file to remote nodes.
  """
  @prefix Atom.to_string(ExLoader.MixProject.project()[:app])

  def copy(remote_node, src) do
    with {:ok, bin} <- read(src),
         {:ok, dst} <- mkdir_p(remote_node, src),
         {:ok, dst} <- write(remote_node, dst, bin) do
      {:ok, dst}
    else
      err -> err
    end
  end

  defp mkdir_p(remote_node, src) do
    dst = "/tmp/#{@prefix}.#{Nanoid.generate()}/#{Path.basename(src)}"
    result = :rpc.call(remote_node, File, :mkdir_p, [Path.dirname(dst)])

    case result do
      :ok ->
        {:ok, dst}

      {:error, reason} ->
        {:error,
         %{
           msg:
             "cannot copy file to target node due to dir creation failure for #{dst}. Reason: #{
               inspect(reason)
             }"
         }}
    end
  end

  defp write(remote_node, dst, bin) do
    result = :rpc.call(remote_node, File, :write, [dst, bin])

    case result do
      :ok ->
        {:ok, dst}

      {:error, reason} ->
        {:error,
         %{msg: "cannot write to file #{dst}. Reason: #{inspect(reason)}", reason: reason}}
    end
  end

  defp read(src) do
    case File.read(src) do
      {:ok, bin} ->
        {:ok, bin}

      {:error, reason} ->
        {:error, %{msg: "cannot read file #{src}. Reason: #{inspect(reason)}", reason: reason}}
    end
  end
end
