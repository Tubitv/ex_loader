defmodule ExLoaderTest do
  use ExUnit.Case
  import FakeServer
  alias ExLoaderTest.Utils

  @test_node_name "exloader_test"
  @slave_node_name "exloader_slave"

  setup_all do
    Node.start(Utils.get_node_name(@test_node_name), :shortnames)
    Utils.start_node(@slave_node_name)

    # stop the remote server and clean up tmp files
    on_exit(fn ->
      Utils.stop_node(@slave_node_name)
      :os.cmd('rm -rf /tmp/ex_loader.*')
    end)

    :ok
  end

  test "load a non-existing module will return error" do
    module_file = ExLoaderTest.Utils.get_path("modules/beam/Elixir.Example.Fab1.beam")
    slave_node = Utils.get_node_name(@slave_node_name)
    assert {:error, %{reason: :enoent}} = ExLoader.load_module(module_file, slave_node)
  end

  test "load a module that is not correct beam file will return error" do
    module_file = ExLoaderTest.Utils.get_path("modules/beam/Elixir.Corrupted.beam")
    slave_node = Utils.get_node_name(@slave_node_name)
    assert {:error, %{reason: :badfile}} = ExLoader.load_module(module_file, slave_node)
  end

  test "load an existing module will make that module available " do
    module_file = ExLoaderTest.Utils.get_path("modules/beam/Elixir.Example.Fab.beam")
    slave_node = Utils.get_node_name(@slave_node_name)

    # module is not in local
    assert_raise(UndefinedFunctionError, fn -> Example.Fab.value(0) end)
    # module is not in slave node
    assert {:badrpc, {:EXIT, {:undef, _}}} = :rpc.call(slave_node, Example.Fab, :value, [0])
    {:ok, module} = ExLoader.load_module(module_file, slave_node)
    assert :rpc.call(slave_node, module, :value, [0]) == 0
  end

  test "load a non-existent tarball" do
    module_file = ExLoaderTest.Utils.get_path("apps/tarball/example_app1.tar.gz")
    slave_node = Utils.get_node_name(@slave_node_name)
    assert {:error, %{reason: :enoent}} = ExLoader.load_release(module_file, slave_node)
  end

  test "load a bad tarball" do
    module_file = ExLoaderTest.Utils.get_path("apps/tarball/corrupted.tar.gz")
    slave_node = Utils.get_node_name(@slave_node_name)
    assert {:error, %{reason: :badfile}} = ExLoader.load_release(module_file, slave_node)
  end

  test "load a tarball which contains applications to be loaded" do
    tarball = ExLoaderTest.Utils.get_path("apps/tarball/example_app.tar.gz")
    slave_node = Utils.get_node_name(@slave_node_name)

    # app is not started in local
    assert_raise(UndefinedFunctionError, fn -> ExampleApp.hello("world") end)
    # app is not in remote node
    assert {:badrpc, {:EXIT, {:undef, _}}} = :rpc.call(slave_node, ExampleApp, :hello, ["world"])
    :ok = ExLoader.load_release(tarball, slave_node)
    assert :rpc.call(slave_node, ExampleApp, :hello, ["world"]) == "hello world"
  end

  describe "load a tarball from http url which contains apps with dependencies" do
    test_with_server "server return the file" do
      tarball = ExLoaderTest.Utils.get_path("apps/tarball/example_complex_app.tar.gz")
      url = "http://#{FakeServer.address()}/example.tar.gz"

      route(
        "/example.tar.gz",
        FakeServer.HTTP.Response.ok(File.read!(tarball), %{
          "content-type" => "application/octet-stream"
        })
      )

      slave_node = Utils.get_node_name(@slave_node_name)

      :ok = ExLoader.load_release(url, slave_node)
      assert :rpc.call(slave_node, App1, :hello, ["world"]) == "hello world"
      assert :rpc.call(slave_node, App2, :hello, ["world"]) == "hello world"

      # test http server works as expected
      %HTTPoison.Response{body: body} =
        Utils.http_get("http://127.0.0.1:8888/hello/?msg=blockchain")

      assert Jason.decode!(body) == %{"result" => "hello blockchain"}
    end
  end
end
