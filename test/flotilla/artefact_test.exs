defmodule Flotilla.ArtefactTest do
  use ExUnit.Case, async: true

  alias Flotilla.Artefact

  describe "from_keyword/1" do
    test "builds a docker_image artefact" do
      art = Artefact.from_keyword(type: :docker_image, ref: "myapp:1.2.3")
      assert art.type == :docker_image
      assert art.ref == "myapp:1.2.3"
    end

    test "builds a binary artefact" do
      art = Artefact.from_keyword(type: :binary, path: "/tmp/myapp.tar.gz", checksum: "abc123")
      assert art.type == :binary
      assert art.path == "/tmp/myapp.tar.gz"
      assert art.checksum == "abc123"
    end

    test "raises on missing required :type" do
      assert_raise KeyError, fn -> Artefact.from_keyword(ref: "x") end
    end
  end

  describe "validate/1" do
    test "valid docker_image needs ref" do
      assert {:error, _} = Artefact.validate(%Artefact{type: :docker_image, ref: nil})
      assert :ok = Artefact.validate(%Artefact{type: :docker_image, ref: "x:1"})
    end

    test "valid binary needs path" do
      assert {:error, _} = Artefact.validate(%Artefact{type: :binary, path: nil})
      assert :ok = Artefact.validate(%Artefact{type: :binary, path: "/x"})
    end

    test "rejects unknown type" do
      assert {:error, _} = Artefact.validate(%Artefact{type: :unknown, ref: "x"})
    end
  end

  describe "id/1" do
    test "formats docker_image as docker:ref" do
      assert Artefact.id(%Artefact{type: :docker_image, ref: "x:1"}) == "docker:x:1"
    end

    test "formats source as git:ref" do
      assert Artefact.id(%Artefact{type: :source, ref: "abc123"}) == "git:abc123"
    end

    test "formats binary as type:path" do
      assert Artefact.id(%Artefact{type: :binary, path: "/x"}) == "binary:/x"
    end
  end
end
