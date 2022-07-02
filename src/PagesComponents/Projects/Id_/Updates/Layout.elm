module PagesComponents.Projects.Id_.Updates.Layout exposing (Model, handleLayout)

import Conf
import Dict
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Projects.Id_.Models exposing (LayoutDialog, LayoutMsg(..), Msg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapErdMCmd, mapLayouts, mapNewLayoutM, setCurrentLayout, setName, setNewLayout)
import Services.Toasts as Toasts
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

        LDelete name ->
            model |> mapErdMCmd (deleteLayout name)


createLayout : LayoutName -> Time.Posix -> Erd -> ( Erd, Cmd Msg )
createLayout name now erd =
    erd.layouts
        |> Dict.get name
        |> Maybe.mapOrElse
            (\_ -> ( erd, Toasts.error Toast ("Layout " ++ name ++ " already exists") ))
            (erd
                |> Erd.currentLayout
                |> (\layout -> { layout | createdAt = now, updatedAt = now })
                |> (\layout -> ( erd |> setCurrentLayout name |> mapLayouts (Dict.insert name layout), Ports.track (Track.createLayout layout) ))
            )


loadLayout : LayoutName -> Erd -> ( Erd, Cmd Msg )
loadLayout name erd =
    erd.layouts
        |> Dict.get name
        |> Maybe.mapOrElse
            (\layout ->
                ( erd |> setCurrentLayout name
                , Cmd.batch [ Ports.observeTablesSize (layout.tables |> List.map .id), Ports.track (Track.loadLayout layout) ]
                )
            )
            ( erd, Cmd.none )


deleteLayout : LayoutName -> Erd -> ( Erd, Cmd Msg )
deleteLayout name erd =
    if name == erd.currentLayout then
        ( erd, Toasts.warning Toast ("Can't delete current layout (" ++ name ++ ")") )

    else
        erd.layouts
            |> Dict.get name
            |> Maybe.map (\layout -> ( erd |> mapLayouts (Dict.remove name), Ports.track (Track.deleteLayout layout) ))
            |> Maybe.withDefault ( erd, Toasts.warning Toast ("Can't find layout '" ++ name ++ "' to delete") )
