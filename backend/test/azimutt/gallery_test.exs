defmodule Azimutt.GalleryTest do
  use Azimutt.DataCase
  alias Azimutt.Gallery
  alias Azimutt.Utils.Result

  describe "samples" do
    import Azimutt.AccountsFixtures
    import Azimutt.OrganizationsFixtures
    import Azimutt.ProjectsFixtures
    import Azimutt.GalleryFixtures

    test "list_samples/0 returns all samples" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      sample = sample_fixture(project)
      assert [sample.id] == Gallery.list_samples() |> Enum.map(fn s -> s.id end)
    end

    test "get_sample!/1 returns the sample with given id" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      sample = sample_fixture(project)
      assert {:ok, sample.id} == Gallery.get_sample(sample.slug) |> Result.map(fn s -> s.id end)
    end
  end
end
