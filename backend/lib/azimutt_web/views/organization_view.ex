defmodule AzimuttWeb.OrganizationView do
  use AzimuttWeb, :view

  def last_update(datetime) do
    {:ok, relative_str} = datetime |> Timex.format("{relative}", :relative)
    relative_str
  end

  def event_description(%{name: "editor_layout_created", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "created a new layout on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_layout_deleted", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "deleted a layout on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_memo_created", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "created a new memo on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_memo_deleted", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "deleted a memo on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_memo_updated", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "updated a new memo on ",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_notes_created", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "created a new note on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_notes_deleted", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "deleted a note on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_notes_updated", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "updated a note on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_source_added", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "added a source on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_source_deleted", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "deleted a source on",
      destination: project.name
    }
  end

  def event_description(%{name: "editor_source_refreshed", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "refreshed a source on",
      destination: project.name
    }
  end

  def event_description(%{name: "project_created", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "created a new project named",
      destination: project.name
    }
  end

  def event_description(%{name: "project_deleted", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "deleted",
      destination: project.name
    }
  end

  def event_description(%{name: "project_loaded", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "has consulted",
      destination: project.name
    }
  end

  def event_description(%{name: "project_updated", created_by: user, project: project}) do
    %{
      author: user.name,
      action: "updated",
      destination: project.name
    }
  end

  ### here to handle unknown events and prevent the view to cash.
  ### This is a temporary solution until we have a better way to handle events
  def event_description(created_by: user, project: project) do
    %{
      author: user.name,
      action: "have done something on",
      destination: project.name
    }
  end
end
