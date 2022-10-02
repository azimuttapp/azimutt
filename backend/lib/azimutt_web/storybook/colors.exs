defmodule AzimuttWeb.Storybook.Colors do
  use PhxLiveStorybook.Entry, :page
  def icon, do: "fat fa-swatchbook"

  def navigation do
    [
      {:default, "Default", ""},
      {:primary, "Primary", ""},
      {:info, "Info", ""},
      {:success, "Success", ""},
      {:warning, "Warning", ""},
      {:danger, "Danger", ""}
    ]
  end

  def render(%{tab: :default}), do: render_color(%{color: Storybook.Colors.Default})
  def render(%{tab: :primary}), do: render_color(%{color: Storybook.Colors.Primary})
  def render(%{tab: :info}), do: render_color(%{color: Storybook.Colors.Info})
  def render(%{tab: :success}), do: render_color(%{color: Storybook.Colors.Success})
  def render(%{tab: :warning}), do: render_color(%{color: Storybook.Colors.Warning})
  def render(%{tab: :danger}), do: render_color(%{color: Storybook.Colors.Danger})

  defp render_color(assigns) do
    ~H"""
    <div class="grid grid-cols-6 gap-x-6 gap-y-12 max-w-3xl mx-auto">
      <div class="col-span-6 md:col-span-2">
        <div class={
          "p-2 text-white flex flex-col space-y-1 justify-center items-center rounded-md #{@color.info.name}"
        }>
          <code class="text-xl"><%= @color.info.main_color_hex %></code>
          <code class="text-base opacity-75"><%= @color.info.main_color %></code>
        </div>
      </div>

      <div class="col-span-6 md:col-span-4 text-lg flex flex-col justify-center">
        <%= @color.info.description %>
      </div>

      <div class="col-span-6 grid grid-cols-6 gap-x-6 gap-y-5">
        <%= for txt_style <- [:text, :text_secondary, :text_informative, :text_hover], txt_class = Map.get(@color.styles, txt_style) do %>
          <%= if txt_class do %>
            <div class="col-span-3">
              <div class="mb-3 font-medium"><%= txt_class %></div>
              <div class={txt_class}>
                Lorem ipsum dolor sit amet consectetur adipisicing elit.
              </div>
            </div>
          <% end %>
        <% end %>
      </div>

      <%= if border_class = Map.get(@color.styles, :border) do %>
        <div class="col-span-6">
          <div class="font-medium"><%= border_class %></div>
          <div class={"border-b-2 h-8 #{border_class}"}></div>
          <div class={"border-b-2 h-8 border-dashed #{border_class}"}></div>
        </div>
      <% end %>

      <div class="col-span-6 grid grid-cols-6 gap-x-6 gap-y-5">
        <%= for bg_style <- [:bg, :bg_hover, :bg_disabled], bg_class = Map.get(@color.styles, bg_style) do %>
          <%= if bg_class do %>
            <div class="col-span-6 md:col-span-3">
              <div class="mb-3 font-medium"><%= bg_class %></div>
              <div class={
                "p-4 text-white flex flex-col space-y-2 justify-center rounded-md #{bg_class}"
              }>
                <%= if text_class = Map.get(@color.styles, :text) do %>
                  <div class={text_class}>
                    Lorem Ipsum
                  </div>
                <% end %>
                <%= if text_secondary_class = Map.get(@color.styles, :text_secondary) do %>
                  <div class={text_secondary_class}>
                    dolor sit amet consectetur adipisicing elit. Ullam, voluptate.
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>

      <%= for {btn_style, btn_name} <- [{:button, "Normal"}, {:button_hover, "Hover"}, {:button_focus, "Focus"}, {:button_disabled, "Disabled"}],
            btn_class = Map.get(@color.styles, btn_style) do %>
        <%= if btn_class do %>
          <div class="col-span-6 md:col-span-2">
            <div class="mb-3 font-medium"><%= String.split(btn_class, " ") |> hd() %></div>
            <div class={
              "py-2 px-4 border text-sm font-medium rounded-md text-center outline-none ring-2 ring-offset-2 #{btn_class}"
            }>
              <%= btn_name %>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>

    """
  end
end

defmodule Storybook.Colors.Default do
  def info do
    %{
      name: "bg-default",
      main_color: "gray-600",
      main_color_hex: "#4B5563",
      description: "Default color will be used for almost all texts, borders and secondary actions."
    }
  end

  def styles do
    %{
      text: "text-default-txt",
      text_secondary: "text-default-txt-secondary",
      text_informative: "text-default-txt-informative",
      text_hover: "text-default-txt-hover",
      border: "border-default-border",
      bg: "bg-default-bg",
      bg_hover: "bg-default-bg-hover",
      bg_disabled: "bg-default-bg-disabled",
      button: "bg-white border-default-btn text-default-text ring-transparent",
      button_hover: "bg-default-btn-hover border-default-btn text-default-text ring-transparent",
      button_focus: "ring-default-btn-focus bg-white border-default-btn text-default-text",
      button_disabled: "bg-default-btn-disabled text-default-txt-informative ring-transparent cursor-not-allowed"
    }
  end
end

defmodule Storybook.Colors.Primary do
  def info do
    %{
      name: "bg-primary",
      main_color: "indigo-600",
      main_color_hex: "#4F46E5",
      description: "Primary application Color. should be used for main actions, highlights and titles."
    }
  end

  def styles do
    %{
      text: "text-primary-txt",
      text_secondary: "text-primary-txt-secondary",
      bg: "bg-primary-bg",
      bg_hover: "bg-primary-bg-hover",
      button: "bg-primary-btn border-transparent text-white ring-transparent",
      button_hover: "bg-primary-btn-hover border-transparent text-white ring-transparent",
      button_focus: "ring-primary-btn-focus bg-primary-btn border-transparent text-white",
      button_disabled: "bg-primary-btn-disabled text-white ring-transparent cursor-not-allowed"
    }
  end
end

defmodule Storybook.Colors.Info do
  def info do
    %{
      name: "bg-info",
      main_color: "blue-500",
      main_color_hex: "#3B82F6",
      description: "Info color is meant deliver guidance messages to users"
    }
  end

  def styles do
    %{
      text: "text-info-txt",
      text_secondary: "text-info-txt-secondary",
      bg: "bg-info-bg",
      bg_hover: "bg-info-bg-hover",
      button: "bg-info-btn border-transparent text-white ring-transparent",
      button_hover: "bg-info-btn-hover border-transparent text-white ring-transparent",
      button_focus: "ring-info-btn-focus bg-info-btn border-transparent text-white",
      button_disabled: "bg-info-btn-disabled text-white ring-transparent cursor-not-allowed"
    }
  end
end

defmodule Storybook.Colors.Warning do
  def info do
    %{
      name: "bg-warning",
      main_color: "amber-500",
      main_color_hex: "#F59E0B",
      description: "Warning color will inform the user that a dangerous situation may happen."
    }
  end

  def styles do
    %{
      text: "text-warning-txt",
      text_secondary: "text-warning-txt-secondary",
      bg: "bg-warning-bg",
      bg_hover: "bg-warning-bg-hover",
      button: "bg-warning-btn border-transparent text-white ring-transparent",
      button_hover: "bg-warning-btn-hover border-transparent text-white ring-transparent",
      button_focus: "ring-warning-btn-focus bg-warning-btn border-transparent text-white",
      button_disabled: "bg-warning-btn-disabled text-white ring-transparent cursor-not-allowed"
    }
  end
end

defmodule Storybook.Colors.Success do
  def info do
    %{
      name: "bg-success",
      main_color: "emerald-500",
      main_color_hex: "#34D399",
      description: "Success color should be used to acknowledge users that their action succedeed"
    }
  end

  def styles do
    %{
      text: "text-success-txt",
      text_secondary: "text-success-txt-secondary",
      bg: "bg-success-bg",
      bg_hover: "bg-success-bg-hover",
      button: "bg-success-btn border-transparent text-white ring-transparent",
      button_hover: "bg-success-btn-hover border-transparent text-white ring-transparent",
      button_focus: "ring-success-btn-focus bg-success-btn border-transparent text-white",
      button_disabled: "bg-success-btn-disabled text-white ring-transparent cursor-not-allowed"
    }
  end
end

defmodule Storybook.Colors.Danger do
  def info do
    %{
      name: "bg-danger",
      main_color: "red-500",
      main_color_hex: "#EF4444",
      description: "Danger color should be used to report errors or to present destructive actions. "
    }
  end

  def styles do
    %{
      text: "text-danger-txt",
      text_secondary: "text-danger-txt-secondary",
      bg: "bg-danger-bg",
      bg_hover: "bg-danger-bg-hover",
      border: "border-danger-border",
      button: "bg-danger-btn border-transparent text-white ring-transparent",
      button_hover: "bg-danger-btn-hover border-transparent text-white ring-transparent",
      button_focus: "ring-danger-btn-focus bg-danger-btn border-transparent text-white",
      button_disabled: "bg-danger-btn-disabled text-white ring-transparent cursor-not-allowed"
    }
  end
end
