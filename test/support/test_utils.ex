defmodule ExLoaderTest.Utils do
  @moduledoc false
  alias ExLoader.MixProject

  def get_path(path) do
    MixProject.project()[:app]
    |> Application.app_dir()
    |> Path.join("priv/fixture/#{path}")
  end
end
