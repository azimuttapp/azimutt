defmodule Azimutt.Utils.SlugmeTest do
  use ExUnit.Case
  alias Azimutt.Utils.Slugme
  @alphanumerics Enum.concat([?A..?Z, ?a..?z, ?0..?9]) |> List.to_string()

  test "alphanumeric characters to lowercase" do
    assert Slugme.slugify(@alphanumerics) == String.downcase(@alphanumerics)
  end

  test "replace bad chars" do
    assert Slugme.slugify(" %*my Organization Name)") == "my-organization-name"
    assert Slugme.slugify("%*my-Organization-)Name)") == "my-organization-name"
    assert Slugme.slugify("-%*my-Organization-)Name) ") == "my-organization-name"
    assert Slugme.slugify("-%*my-Organization.Name) ") == "my-organization-name"
  end

  test "collapse multiple -" do
    assert Slugme.slugify("--my--organization--name") == "my-organization-name"
    assert Slugme.slugify("-my-organization-name") == "my-organization-name"
    assert Slugme.slugify("--my-organization-name--") == "my-organization-name"
    assert Slugme.slugify("---my----organization-------name--") == "my-organization-name"
  end
end
