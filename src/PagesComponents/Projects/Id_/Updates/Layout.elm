module PagesComponents.Projects.Id_.Updates.Layout exposing (Model, handleLayout)

import Dict
import Libs.Bool as B
import Libs.Dict as D
import Libs.Maybe as M
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.Layout as Layout
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.App.Updates.Helpers exposing (setLayout, setLayouts, setProject, setProjectWithCmd)
import PagesComponents.Projects.Id_.Models exposing (LayoutMsg(..), Msg(..))
import Ports exposing (observeTablesSize, saveProject, track)
import Time
import Tracking


type alias Model x =
    { x
        | newLayout : Maybe LayoutName
        , project : Maybe Project
    }


handleLayout : LayoutMsg -> Model x -> ( Model x, Cmd Msg )
handleLayout msg model =
    case msg of
        LOpen ->
            ( { model | newLayout = Just "" }, T.sendAfter 1 ModalOpen )

        LEdit name ->
            ( { model | newLayout = Just name }, Cmd.none )

        LCreate name ->
            { model | newLayout = Nothing } |> setProjectWithCmd (createLayout name)

        LCancel ->
            ( { model | newLayout = Nothing }, Cmd.none )

        LLoad name ->
            model |> setProjectWithCmd (loadLayout name)

        LUnload ->
            ( model |> setProject unloadLayout, Cmd.none )

        LUpdate name ->
            model |> setProjectWithCmd (updateLayout name)

        LDelete name ->
            model |> setProjectWithCmd (deleteLayout name)


createLayout : LayoutName -> Project -> ( Project, Cmd Msg )
createLayout name project =
    -- TODO check that layout name does not already exist
    { project | usedLayout = Just name }
        |> setLayouts (Dict.update name (\_ -> Just project.layout))
        |> (\newSchema -> ( newSchema, Cmd.batch [ saveProject newSchema, track (Tracking.events.createLayout project.layout) ] ))


loadLayout : LayoutName -> Project -> ( Project, Cmd Msg )
loadLayout name project =
    project.layouts
        |> Dict.get name
        |> M.mapOrElse
            (\layout ->
                ( { project | usedLayout = Just name } |> setLayout (\_ -> layout)
                , Cmd.batch [ layout.tables |> List.map .id |> observeTablesSize, track (Tracking.events.loadLayout layout) ]
                )
            )
            ( project, Cmd.none )


unloadLayout : Project -> Project
unloadLayout project =
    { project | usedLayout = Nothing }


updateLayout : LayoutName -> Project -> ( Project, Cmd Msg )
updateLayout name project =
    -- TODO check that layout name already exist
    { project | usedLayout = Just name }
        |> setLayouts (Dict.update name (\_ -> Just project.layout))
        |> (\newSchema -> ( newSchema, track (Tracking.events.updateLayout project.layout) ))


deleteLayout : LayoutName -> Project -> ( Project, Cmd Msg )
deleteLayout name project =
    { project | usedLayout = B.cond (project.usedLayout == Just name) Nothing project.usedLayout }
        |> setLayouts (Dict.update name (\_ -> Nothing))
        |> (\newSchema -> ( newSchema, track (Tracking.events.deleteLayout (project.layouts |> D.getOrElse name (Layout.init (Time.millisToPosix 0)))) ))
