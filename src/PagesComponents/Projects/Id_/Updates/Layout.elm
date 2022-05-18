module PagesComponents.Projects.Id_.Updates.Layout exposing (Model, handleLayout)

import Conf
import Dict
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Projects.Id_.Models exposing (LayoutDialog, LayoutMsg(..), Msg(..), toastError, toastSuccess)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapErdM, mapErdMCmd, mapLayouts, mapNewLayoutM, mapUsedLayout, setCanvas, setName, setNewLayout, setShownTables, setTableProps, setUsedLayout)
import Time
import Track


type alias Model x =
    { x
        | newLayout : Maybe LayoutDialog
        , erd : Maybe Erd
    }


handleLayout : Time.Posix -> LayoutMsg -> Model x -> ( Model x, Cmd Msg )
handleLayout now msg model =
    case msg of
        LOpen ->
            ( model |> setNewLayout (Just { id = Conf.ids.newLayoutDialog, name = "" }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.newLayoutDialog), Ports.track Track.openSaveLayout ] )

        LEdit name ->
            ( model |> mapNewLayoutM (setName name), Cmd.none )

        LCreate name ->
            model |> setNewLayout Nothing |> mapErdMCmd (createLayout name now)

        LCancel ->
            ( model |> setNewLayout Nothing, Cmd.none )

        LLoad name ->
            model |> mapErdMCmd (loadLayout name)

        LUnload ->
            ( model |> mapErdM unloadLayout, Cmd.none )

        LUpdate name ->
            model |> mapErdMCmd (updateLayout name now)

        LDelete name ->
            model |> mapErdMCmd (deleteLayout name)


createLayout : LayoutName -> Time.Posix -> Erd -> ( Erd, Cmd Msg )
createLayout name now erd =
    erd.layouts
        |> Dict.get name
        |> Maybe.mapOrElse
            (\_ -> ( erd, Cmd.batch [ T.send (toastError ("Layout " ++ name ++ " already exists")) ] ))
            (let
                layout : Layout
                layout =
                    Erd.unpackLayout erd.canvas erd.tableProps erd.shownTables now now
             in
             erd
                |> setUsedLayout (Just name)
                |> mapLayouts (Dict.insert name layout)
                |> (\newErd -> ( newErd, Ports.track (Track.createLayout layout) ))
            )


loadLayout : LayoutName -> Erd -> ( Erd, Cmd Msg )
loadLayout name erd =
    erd.layouts
        |> Dict.get name
        |> Maybe.mapOrElse
            (\layout ->
                let
                    ( canvas, tableProps, shownTables ) =
                        Erd.createLayout erd.relationsByTable erd.notes layout
                in
                ( erd |> setUsedLayout (Just name) |> setCanvas canvas |> setTableProps tableProps |> setShownTables shownTables
                , Cmd.batch [ Ports.observeTablesSize shownTables, Ports.track (Track.loadLayout layout) ]
                )
            )
            ( erd, Cmd.none )


unloadLayout : Erd -> Erd
unloadLayout erd =
    erd |> setUsedLayout Nothing


updateLayout : LayoutName -> Time.Posix -> Erd -> ( Erd, Cmd Msg )
updateLayout name now erd =
    erd.usedLayout
        |> Maybe.andThen (\l -> erd.layouts |> Dict.get l)
        |> Maybe.mapOrElse
            (\layout ->
                let
                    newLayout : Layout
                    newLayout =
                        Erd.unpackLayout erd.canvas erd.tableProps erd.shownTables layout.createdAt now
                in
                erd
                    |> setUsedLayout (Just name)
                    |> mapLayouts (Dict.insert name newLayout)
                    |> (\newErd -> ( newErd, Cmd.batch [ T.send (toastSuccess ("Saved to layout " ++ name)), Ports.track (Track.updateLayout newLayout) ] ))
            )
            ( erd, Cmd.batch [ T.send (toastError ("Can't find layout " ++ name)), Ports.track (Track.notFoundLayout name) ] )


deleteLayout : LayoutName -> Erd -> ( Erd, Cmd Msg )
deleteLayout name erd =
    (erd.layouts |> Dict.get name)
        |> Maybe.mapOrElse
            (\l -> ( erd |> mapUsedLayout (Maybe.filter (\n -> n /= name)) |> mapLayouts (Dict.remove name), Ports.track (Track.deleteLayout l) ))
            ( erd, Cmd.none )
