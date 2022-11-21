defmodule Azimutt.GalleryTest do
  use Azimutt.DataCase

  alias Azimutt.Gallery

  describe "samples" do
    alias Azimutt.Gallery.Sample

    import Azimutt.GalleryFixtures

    @invalid_attrs %{analysis: nil, banner: nil, color: nil, description: nil, icon: nil, tips: nil, website: nil}

    test "list_samples/0 returns all samples" do
      sample = sample_fixture()
      assert Gallery.list_samples() == [sample]
    end

    test "get_sample!/1 returns the sample with given id" do
      sample = sample_fixture()
      assert Gallery.get_sample!(sample.id) == sample
    end

    test "create_sample/1 with valid data creates a sample" do
      valid_attrs = %{
        analysis: "some analysis",
        banner: "some banner",
        color: "some color",
        description: "some description",
        icon: "some icon",
        tips: "some tips",
        website: "some website"
      }

      assert {:ok, %Sample{} = sample} = Gallery.create_sample(valid_attrs)
      assert sample.analysis == "some analysis"
      assert sample.banner == "some banner"
      assert sample.color == "some color"
      assert sample.description == "some description"
      assert sample.icon == "some icon"
      assert sample.tips == "some tips"
      assert sample.website == "some website"
    end

    test "create_sample/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gallery.create_sample(@invalid_attrs)
    end

    test "update_sample/2 with valid data updates the sample" do
      sample = sample_fixture()

      update_attrs = %{
        analysis: "some updated analysis",
        banner: "some updated banner",
        color: "some updated color",
        description: "some updated description",
        icon: "some updated icon",
        tips: "some updated tips",
        website: "some updated website"
      }

      assert {:ok, %Sample{} = sample} = Gallery.update_sample(sample, update_attrs)
      assert sample.analysis == "some updated analysis"
      assert sample.banner == "some updated banner"
      assert sample.color == "some updated color"
      assert sample.description == "some updated description"
      assert sample.icon == "some updated icon"
      assert sample.tips == "some updated tips"
      assert sample.website == "some updated website"
    end

    test "update_sample/2 with invalid data returns error changeset" do
      sample = sample_fixture()
      assert {:error, %Ecto.Changeset{}} = Gallery.update_sample(sample, @invalid_attrs)
      assert sample == Gallery.get_sample!(sample.id)
    end

    test "delete_sample/1 deletes the sample" do
      sample = sample_fixture()
      assert {:ok, %Sample{}} = Gallery.delete_sample(sample)
      assert_raise Ecto.NoResultsError, fn -> Gallery.get_sample!(sample.id) end
    end

    test "change_sample/1 returns a sample changeset" do
      sample = sample_fixture()
      assert %Ecto.Changeset{} = Gallery.change_sample(sample)
    end
  end
end
