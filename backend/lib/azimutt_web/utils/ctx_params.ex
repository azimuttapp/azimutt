defmodule AzimuttWeb.Utils.CtxParams do
  @moduledoc """
  Parse generic optional params and make them easily accessible.
  """
  use TypedStruct
  alias AzimuttWeb.Utils.CtxParams

  # TODO: other possible common params: `q`, `sort`, `filter`, `page`...
  typedstruct enforce: true do
    field :expand, list(String.t())
  end

  def empty do
    %CtxParams{
      expand: []
    }
  end

  def from_params(params) do
    %CtxParams{
      expand:
        (params["expand"] || "")
        |> String.split(",")
        |> Enum.map(fn e -> String.trim(e) end)
        |> Enum.filter(fn e -> String.length(e) > 0 end)
    }
  end

  def nested(%CtxParams{} = ctx, attr) do
    %CtxParams{
      expand:
        ctx.expand
        |> Enum.filter(fn e -> e |> String.starts_with?("#{attr}.") end)
        |> Enum.map(fn e -> e |> String.replace_prefix("#{attr}.", "") end)
    }
  end
end
