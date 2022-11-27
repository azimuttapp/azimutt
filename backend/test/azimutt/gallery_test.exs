defmodule Azimutt.GalleryTest do
  use Azimutt.DataCase
  alias Azimutt.Gallery

  describe "samples" do
    import Azimutt.GalleryFixtures

    @tag :skip
    test "list_samples/0 returns all samples" do
      sample = sample_fixture()
      assert Gallery.list_samples() == [sample]
    end

    @tag :skip
    test "get_sample!/1 returns the sample with given id" do
      sample = sample_fixture()
      assert Gallery.get_sample(sample.slug) == {:ok, sample}
    end
  end
end
