module PagesComponents.Organization_.Project_.Updates.Layout exposing (Model, handleLayout)

import Dict
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Organization_.Project_.Models exposing (LayoutMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyCmd)
import Ports
import Services.Lenses exposing (mapErdMCmd, mapLayouts, setCurrentLayout)
import Services.Toasts as Toasts
import Track


type alias Model x =
    { x | conf : ErdConf, dirty : Bool, erd : Maybe Erd }


handleLayout : LayoutMsg -> Model x -> ( Model x, Cmd Msg )
handleLayout msg model =
    case msg of
        LLoad name ->
            model |> mapErdMCmd (loadLayout name) |> setDirtyCmd

        LDelete name ->
            model |> mapErdMCmd (deleteLayout name) |> setDirtyCmd


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
        ( erd, "Can't delete current layout (" ++ name ++ ")" |> Toasts.warning |> Toast |> T.send )

    else
        erd.layouts
            |> Dict.get name
            |> Maybe.map (\layout -> ( erd |> mapLayouts (Dict.remove name), Ports.track (Track.deleteLayout layout) ))
            |> Maybe.withDefault ( erd, "Can't find layout '" ++ name ++ "' to delete" |> Toasts.warning |> Toast |> T.send )
