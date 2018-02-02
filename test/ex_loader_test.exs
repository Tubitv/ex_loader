defmodule ExLoaderTest do
  use ExUnit.Case

  @node_name :exloader_test@localhost

  setup_all do
    Node.start(@node_name)
    :ok
  end

  test "load an existing module will make that module available " do
    module_file = ExLoaderTest.Utils.get_path("modules/beam/Elixir.Example.Fab.beam")
    my_node = node()

    # module is not in local
    assert_raise(UndefinedFunctionError, fn -> Example.Fab.value(0) end)
    # module is not in remote node (actually node(self))
    assert {:badrpc, {:EXIT, {:undef, _}}} = :rpc.call(my_node, Example.Fab, :value, [0])
    {:ok, module} = ExLoader.load_module(module_file, my_node)
    assert :rpc.call(my_node, module, :value, [0]) == 0
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
    tarball = ExLoaderTest.Utils.get_path("apps/tarball/example_app.tar.gz")
    my_node = node()

    # app is not started in local
    assert_raise(UndefinedFunctionError, fn -> ExampleApp.hello("world") end)
    # app is not in remote node (actually node(self))
    assert {:badrpc, {:EXIT, {:undef, _}}} = :rpc.call(my_node, ExampleApp, :hello, ["world"])
    :ok = ExLoader.load_release(tarball, my_node)
    assert :rpc.call(my_node, ExampleApp, :hello, ["world"]) == "hello world"
  end
end
