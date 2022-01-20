module PagesComponents.App.Updates.Layout exposing (handleLayout)

import Dict
import Libs.Bool as B
import Libs.Maybe as M
import Models.Project exposing (Project)
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.App.Models exposing (LayoutMsg(..), Model, Msg)
import Ports
import Services.Lenses exposing (mapLayouts, mapProjectM, mapProjectMCmd, mapUsedLayout, setLayout, setNewLayout, setUsedLayout)
import Track


type alias Model x =
    { x
        | newLayout : Maybe LayoutName
        , project : Maybe Project
    }


handleLayout : LayoutMsg -> Model x -> ( Model x, Cmd Msg )
handleLayout msg model =
    case msg of
        LNew name ->
            ( model |> setNewLayout (B.cond (String.length name == 0) Nothing (Just name)), Cmd.none )

        LCreate name ->
            model |> setNewLayout Nothing |> mapProjectMCmd (createLayout name)

        LLoad name ->
            model |> mapProjectMCmd (loadLayout name)

        LUnload ->
            ( model |> mapProjectM unloadLayout, Cmd.none )

        LUpdate name ->
            model |> mapProjectMCmd (updateLayout name)

        LDelete name ->
            model |> mapProjectMCmd (deleteLayout name)


createLayout : LayoutName -> Project -> ( Project, Cmd Msg )
createLayout name project =
    -- TODO check that layout name does not already exist
    project
        |> setUsedLayout (Just name)
        |> mapLayouts (Dict.update name (\_ -> Just project.layout))
        |> (\newSchema -> ( newSchema, Cmd.batch [ Ports.saveProject newSchema, Ports.track (Track.createLayout project.layout) ] ))


loadLayout : LayoutName -> Project -> ( Project, Cmd Msg )
loadLayout name project =
    project.layouts
        |> Dict.get name
        |> M.mapOrElse
            (\layout ->
                ( project |> setUsedLayout (Just name) |> setLayout layout
                , Cmd.batch [ layout.tables |> List.map .id |> Ports.observeTablesSize, Ports.activateTooltipsAndPopovers, Ports.track (Track.loadLayout layout) ]
                )
            )
            ( project, Cmd.none )


unloadLayout : Project -> Project
unloadLayout project =
    project |> setUsedLayout Nothing


updateLayout : LayoutName -> Project -> ( Project, Cmd Msg )
updateLayout name project =
    -- TODO check that layout name already exist
    project
        |> setUsedLayout (Just name)
        |> mapLayouts (Dict.update name (\_ -> Just project.layout))
        |> (\newSchema -> ( newSchema, Cmd.batch [ Ports.saveProject newSchema, Ports.track (Track.updateLayout project.layout) ] ))


deleteLayout : LayoutName -> Project -> ( Project, Cmd Msg )
deleteLayout name project =
    (project.layouts |> Dict.get name)
        |> M.mapOrElse
            (\l -> ( project |> mapUsedLayout (M.filter (\n -> n /= name)) |> mapLayouts (Dict.remove name), Ports.track (Track.deleteLayout l) ))
            ( project, Cmd.none )
