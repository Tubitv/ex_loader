defmodule ExLoaderTest.Utils do
  @moduledoc false
  alias ExLoader.MixProject

  def get_path(path) do
    MixProject.project()[:app]
    |> Application.app_dir()
    |> Path.join("priv/fixture/#{path}")
  end

  def start_node(name) do
    cmd = "iex --sname #{name} --cookie #{:erlang.get_cookie()} --detached"
    :os.cmd(to_charlist(cmd))
    connect(name)
  end

  def stop_node(name) do
    node_name = get_node_name(name)
    :rpc.call(node_name, :init, :stop, [])
  end

  def get_node_name(name) do
    {:ok, hostname} = :inet.gethostname()
    :"#{name}@#{to_string(hostname)}"
  end

  def http_get(url), do: http_get(url, 5)
  def http_get(_url, 0), do: :error

  def http_get(url, n) do
    :timer.sleep(50)

    case HTTPoison.get(url) do
      {:ok, res} -> res
      {:error, _} -> http_get(url, n - 1)
    end
  end

  defp connect(name) do
    :timer.sleep(30)

    case Node.connect(get_node_name(name)) do
      true -> true
      false -> connect(name)
    end
  end
end
