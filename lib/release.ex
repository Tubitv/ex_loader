defmodule ExLoader.Release do
  @moduledoc """
  Extract info from rel file and find out application needs to be loaded / started
  """

  def load(remote_node, base, apps \\ nil) do
    with {:ok, rel_file} <- get_rel_file(remote_node, base),
         {:ok, ver, new_apps} <- get_new_apps(remote_node, rel_file),
         {:ok, _paths} <- add_paths(remote_node, base, new_apps),
         :ok <- load_sys_config(remote_node, ver, base) do
      load_apps(remote_node, apps || Enum.map(new_apps, fn app -> elem(app, 0) end))
    else
      err -> err
    end
  end

  defp get_rel_file(remote_node, base) do
    rel_file =
      remote_node
      |> :rpc.call(Path, :wildcard, ["#{base}/releases/*.rel"])
      |> List.first()

    case rel_file do
      nil -> {:error, %{msg: "cannot find rel file: #{rel_file}", reason: :noent}}
      p -> {:ok, p}
    end
  end

  defp get_new_apps(remote_node, rel_file) do
    {:release, {_, ver}, _, apps} = read_config(remote_node, rel_file)

    started_apps =
      Enum.map(:rpc.call(remote_node, Application, :started_applications, []), fn {app, _, _} ->
        app
      end)

    {:ok, ver, Enum.filter(apps, fn app -> elem(app, 0) not in started_apps end)}
  end

  defp add_paths(remote_node, base, apps) do
    paths =
      Enum.map(get_paths(base, apps, remote_node), fn p ->
        :rpc.call(remote_node, :code, :add_path, [to_charlist(p)])
        p
      end)

    {:ok, paths}
  end

  defp load_sys_config(remote_node, ver, base) do
    sys_config = "#{base}/releases/#{ver}/sys.config"

    remote_node
    |> read_config(sys_config)
    |> Enum.each(fn {app, data} ->
      Enum.each(data, fn {k, v} ->
        :rpc.call(remote_node, Application, :put_env, [app, k, v, [persistent: true]])
      end)
    end)

    :ok
  end

  defp load_apps(remote_node, apps) do
    Enum.each(apps, fn app ->
      :rpc.call(remote_node, Application, :ensure_all_started, [app])
    end)
  end

  defp get_paths(base, apps, remote_node) do
    apps
    |> Enum.map(fn app ->
      parent = Path.join(base, "lib/#{elem(app, 0)}-#{elem(app, 1)}")

      :rpc.call(remote_node, File, :ls!, [parent])
      |> Enum.map(&Path.join(parent, &1))
      |> Enum.filter(fn p ->
        :rpc.call(remote_node, File, :dir?, [p]) and Path.basename(p) != "priv"
      end)
    end)
    |> List.flatten()
  end

  defp read_config(remote_node, file) do
    content = :rpc.call(remote_node, File, :read!, [file])
    {:ok, tokens, _} = :erl_scan.string(to_charlist(content))
    {:ok, [form]} = :erl_parse.parse_exprs(tokens)
    {:value, v, _} = :erl_eval.expr(form, [])
    v
  end
end
