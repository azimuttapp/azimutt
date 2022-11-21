defmodule Azimutt.GalleryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Azimutt.Gallery` context.
  """

  @doc """
  Generate a sample.
  """
  def sample_fixture(attrs \\ %{}) do
    {:ok, sample} =
      attrs
      |> Enum.into(%{
        analysis: "some analysis",
        banner: "some banner",
        color: "some color",
        description: "some description",
        icon: "some icon",
        tips: "some tips",
        website: "some website"
      })
      |> Azimutt.Gallery.create_sample()

    sample
  end
end
