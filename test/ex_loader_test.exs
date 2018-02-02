defmodule ExLoaderTest do
  use ExUnit.Case

  @node_name :exloader_test@localhost

  setup_all do
    Node.start(@node_name)
    :ok
  end

  test "load an existing module will make that module available " do
    module_file = ExLoaderTest.Utils.get_path("modules/beam/Elixir.Example.Fab.beam")

    # module is not in local
    assert_raise(UndefinedFunctionError, fn -> Example.Fab.value(0) end)
    # module is not in remote node (actually node(self))
    assert {:badrpc, {:EXIT, {:undef, _}}} = :rpc.call(node(), Example.Fab, :value, [0])
    {:ok, module} = ExLoader.load_module(module_file)
    assert :rpc.call(node(), module, :value, [0]) == 0
  end

  test "load a non-existing module will return error" do
    module_file = ExLoaderTest.Utils.get_path("modules/beam/Elixir.Example.Fab1.beam")
    assert {:error, %{reason: :enoent}} = ExLoader.load_module(module_file)
  end

  test "load a module that is not correct beam file will return error" do
    module_file = ExLoaderTest.Utils.get_path("modules/beam/Elixir.Corrupted.beam")
    assert {:error, %{reason: :badfile}} = ExLoader.load_module(module_file)
  end

  test "load a tarball which contains applications to be loaded" do
    
  end
end
