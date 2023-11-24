defmodule Azimutt.Services.OnboardingSrv do
  @moduledoc false
  alias Azimutt.Accounts
  alias Azimutt.Accounts.User
  alias Azimutt.Tracking.Event

  def on_event(%Event{created_by: user} = event) when not is_nil(user) do
    case find_item(event) do
      nil -> :ok
      item -> add_item(user, item.id)
    end
  end

  def on_event(%Event{created_by: nil}), do: :ok

  def add_item(%User{} = user, item) do
    if user && !Enum.member?(user.data.start_checklist, item) do
      user |> Accounts.set_start_checklist(user.data.start_checklist ++ [item])
    else
      :ok
    end
  end

  def items do
    [
      %{id: "new_project", label: "Create a project and save it", help: "When saving your project, local mode keep all your data on your browser."},
      %{id: "aml", label: "Design or extend your db with AML", help: "Create an AML source from settings or 'Update your schema' button on the bottom right and add a table."},
      %{id: "follow_relation", label: "Navigate schema with relations", help: "Click on colored icons on a table to view related tables, in or out."},
      %{id: "details", label: "Open details for table or column", help: "Double/right click on a table or column to open details about it."},
      %{id: "create_note", label: "Add a note on table or column", help: "Right click on a table header or column, then select 'Add notes' to document it."},
      %{id: "create_memo", label: "Create a layout memo", help: "Double/right click on diagram background and write markdown documentation."},
      %{id: "create_layout", label: "Create a new layout", help: "On center-top, click on the layout name (initial layout) and create a new one."},
      %{id: "data_explorer", label: "Query your database", help: "Open data explorer (bottom right 'Explore your data' icon) and run some queries."},
      %{id: "table_row", label: "Add a table row in a layout", help: "Open a data explorer result row in sidebar and click on 'Add to layout' button."},
      %{id: "follow_data_relation", label: "Navigate data with relations", help: "On a table row, if there is an icon on the right, click on it to view related rows."},
      %{id: "find_path", label: "Search path between tables", help: "Right click on diagram/table header or open features menu and try 'Find path'."},
      %{id: "analyze", label: "Analyze your schema", help: "Open features menu (lightning) and see when 'Analyze your schema' will give you."},
      %{id: "promote", label: "Give us a shout out", help: "Making Azimutt takes a lot of energy, user satisfaction and support boost us. Send some feedback if you feel it."}
    ]
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp find_item(%Event{} = event) do
    items()
    |> Enum.find(fn item ->
      case item.id do
        "new_project" -> event.name == "project_created"
        "aml" -> event.name == "editor_source_refreshed" && event.details["kind"] == "AmlEditor" && event.details["nb_table"] > 0
        "follow_relation" -> event.name == "editor__table__shown" && event.details["from"] == "relation"
        "details" -> event.name == "editor__detail_sidebar__opened" && event.details["level"] in ["table", "column"]
        "create_note" -> event.name == "editor_notes_created"
        "create_memo" -> event.name == "editor_memo_created"
        "create_layout" -> event.name == "editor_layout_created"
        "data_explorer" -> event.name == "data_explorer__query__result"
        "table_row" -> event.name == "data_explorer__table_row__opened"
        "follow_data_relation" -> event.name == "data_explorer__table_row__shown" && event.details["from"] == "relation"
        "find_path" -> event.name == "editor_find_path_searched"
        "analyze" -> event.name == "editor_db_analysis_opened"
        _ -> false
      end
    end)
  end
end
