defmodule AzimuttWeb.Storybook.Components.Brand do
  alias AzimuttWeb.Components.Brand

  # :live_component or :page are also available
  use PhxLiveStorybook.Entry, :component

  def function, do: &Brand.logo/1
  def description, do: "A generic logo"

  def attributes do
    [
      %Attr{id: :variant, type: :string, doc: "Logo variant like logo_{@variant}.svg"},
      %Attr{
        id: :class,
        type: :string,
        doc: "Enforce class"
      }
    ]
  end

  def stories do
    [
      %Story{
        id: :default
      }
    ]
  end
end
