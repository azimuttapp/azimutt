defmodule Azimutt.Utils.Slugme do
  @moduledoc false
  import Ecto.Changeset

  def generate_slug(changeset, field) when is_atom(field) do
    slug = slugify(changeset.changes[field])
    new_slug = make_unique(changeset, slug)

    changeset
    |> put_change(:slug, new_slug)
  end

  def slugify(str) when is_binary(str) do
    str
    |> String.trim()
    |> String.downcase()
    |> String.normalize(:nfd)
    |> replace_bad_chars_by("-")
    |> collapse_multiple("-")
    |> String.replace_prefix("-", "")
    |> String.replace_suffix("-", "")
  end

  # TODO: Work for now, but can be cleaner.
  # Made this because of the current organization changeset (:new and :create steps to refacto).
  def slugify(str) do
    str
  end

  defp replace_bad_chars_by(str, char) do
    str |> String.replace(~r/[^a-z\d-]/u, char)
  end

  defp collapse_multiple(str, char) do
    str |> String.replace(~r/--+/, char)
  end

  defp make_unique(changeset, slug, attempt \\ 1) do
    new_slug = if attempt > 1, do: "#{slug}-#{attempt}", else: slug

    new_changeset =
      changeset
      |> put_change(:slug, new_slug)
      |> unsafe_validate_unique([:slug], Azimutt.Repo)

    if is_slug_unique(new_changeset) do
      new_slug
    else
      make_unique(changeset, slug, attempt + 1)
    end
  end

  defp is_slug_unique(%Ecto.Changeset{valid?: true}), do: true
  defp is_slug_unique(_), do: false
end
