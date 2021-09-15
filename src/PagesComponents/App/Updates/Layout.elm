module PagesComponents.App.Updates.Layout exposing (createLayout, deleteLayout, loadLayout, unloadLayout, updateLayout)

import Dict
import Libs.Bool as B
import Models.Project exposing (LayoutName, Project, initLayout)
import PagesComponents.App.Models exposing (Msg)
import PagesComponents.App.Updates.Helpers exposing (setLayout, setLayouts, setSchema)
import Ports exposing (activateTooltipsAndPopovers, observeTablesSize, saveProject, track)
import Time
import Tracking exposing (events)


createLayout : LayoutName -> Project -> ( Project, Cmd Msg )
createLayout name project =
    -- TODO check that layout name does not already exist
    { project | currentLayout = Just name }
        |> setLayouts (Dict.update name (\_ -> Just project.schema.layout))
        |> (\newSchema -> ( newSchema, Cmd.batch [ saveProject newSchema, track (events.createLayout project.schema.layout) ] ))


loadLayout : LayoutName -> Project -> ( Project, Cmd Msg )
loadLayout name project =
    project.layouts
        |> Dict.get name
        |> Maybe.map
            (\layout ->
                ( { project | currentLayout = Just name } |> setSchema (setLayout (\_ -> layout))
                , Cmd.batch [ layout.tables |> List.map .id |> observeTablesSize, activateTooltipsAndPopovers, track (events.loadLayout layout) ]
                )
            )
        |> Maybe.withDefault ( project, Cmd.none )


updateLayout : LayoutName -> Project -> ( Project, Cmd Msg )
updateLayout name project =
    -- TODO check that layout name already exist
    { project | currentLayout = Just name }
        |> setLayouts (Dict.update name (\_ -> Just project.schema.layout))
        |> (\newSchema -> ( newSchema, Cmd.batch [ saveProject newSchema, track (events.updateLayout project.schema.layout) ] ))


deleteLayout : LayoutName -> Project -> ( Project, Cmd Msg )
deleteLayout name project =
    { project | currentLayout = B.cond (project.currentLayout == Just name) Nothing (Just name) }
        |> setLayouts (Dict.update name (\_ -> Nothing))
        |> (\newSchema -> ( newSchema, Cmd.batch [ saveProject newSchema, track (events.deleteLayout (project.layouts |> Dict.get name |> Maybe.withDefault (initLayout (Time.millisToPosix 0)))) ] ))


unloadLayout : Project -> Project
unloadLayout project =
    { project | currentLayout = Nothing }
