defmodule ExLoader.File do
  @moduledoc """
  copy file to remote nodes.
  """
  alias ExLoader.Adapters

  @adapters %{
    file: Adapters.File,
    http: Adapters.Http
  }

  @prefix Atom.to_string(ExLoader.MixProject.project()[:app])

  def valid_file?(src) do
    adapter = get_adapter(src)

    case adapter do
      nil -> false
      adapter -> apply(adapter, :valid?, [src])
    end
  end

  def copy(remote_node, src) do
    with {:ok, bin} <- read(src),
         {:ok, dst} <- mkdir_p(remote_node, src),
         {:ok, dst} <- write(remote_node, dst, bin) do
      {:ok, dst}
    else
      err -> err
    end
  end

  def uncompress(remote_node, tarball) do
    {:ok, dst} = mkdir_p(remote_node, tarball)

    # uncompress in local with erlang stdlib
    file =
      case read(tarball) do
        {:ok, file} -> file
        err -> throw(err)
      end

    case :erl_tar.extract({:binary, file}, [:memory, :compressed]) do
      {:ok, files} ->
        Enum.each(files, fn {filename, raw} ->
          file_path = Path.join([Path.dirname(dst), filename])

          with :ok <- :rpc.call(remote_node, :filelib, :ensure_dir, [to_charlist(file_path)]),
               {:ok, _} <- write(remote_node, file_path, raw) do
            :ok
          else
            err -> throw(err)
          end
        end)

        {:ok, dst}

      {:error, _} ->
        {:error, %{msg: "failed to uncompress the release tarball: #{tarball}", reason: :badfile}}
    end
  catch
    err -> err
  end

  defp mkdir_p(remote_node, src) do
    dst = "/tmp/#{@prefix}.#{Nanoid.generate()}/#{Path.basename(src)}"

    # erlang  filelib:ensure_dir, must end with "/"
    target_dir_path = to_charlist("#{Path.dirname(dst)}/")
    result = :rpc.call(remote_node, :filelib, :ensure_dir, [target_dir_path])

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
    result = :rpc.call(remote_node, :file, :write_file, [to_charlist(dst), bin])

    case result do
      :ok ->
        {:ok, dst}

      {:error, reason} ->
        {:error,
         %{msg: "cannot write to file #{dst}. Reason: #{inspect(reason)}", reason: reason}}
    end
  end

  defp read(src) do
    adapter = get_adapter(src)

    case adapter do
      nil -> {:error, %{msg: "not supported file #{src}", reason: :badfile}}
      _ -> apply(adapter, :get_content, [src])
    end
  end

  defp get_adapter(src) do
    %URI{scheme: scheme} = URI.parse(src)

    type =
      case scheme do
        nil -> :file
        s when s in ["https", "http", "ftp"] -> :http
        _ -> nil
      end

    Map.get(@adapters, type)
  end
end
