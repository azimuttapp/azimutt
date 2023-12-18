module PagesComponents.Organization_.Project_.Updates.Layout exposing (Model, handleLayout)

import Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Organization_.Project_.Models exposing (LayoutMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyCmd)
import Ports
import Services.Lenses exposing (mapErdMCmd, mapLayouts, setCurrentLayout, setLayoutOnLoad)
import Services.Toasts as Toasts
import Track


type alias Model x =
    { x | conf : ErdConf, dirty : Bool, erd : Maybe Erd }


handleLayout : LayoutMsg -> Model x -> ( Model x, Cmd Msg )
handleLayout msg model =
    case msg of
        LLoad name ->
            model |> mapErdMCmd (loadLayout name)

        LDelete name ->
            model |> mapErdMCmd (deleteLayout name) |> setDirtyCmd


loadLayout : LayoutName -> Erd -> ( Erd, Cmd Msg )
loadLayout name erd =
    erd.layouts
        |> Dict.get name
        |> Maybe.mapOrElse
            (\layout ->
                ( erd |> setCurrentLayout name |> setLayoutOnLoad "fit"
                , Cmd.batch [ Ports.observeLayout layout, Track.layoutLoaded erd.project layout ]
                )
            )
            ( erd, Cmd.none )


deleteLayout : LayoutName -> Erd -> ( Erd, Cmd Msg )
deleteLayout name erd =
    (erd.layouts |> Dict.get name)
        |> Maybe.map
            (\layout ->
                if name == erd.currentLayout then
                    let
                        names : List LayoutName
                        names =
                            erd.layouts |> Dict.keys |> List.sortBy String.toLower

                        next : Maybe LayoutName
                        next =
                            (names |> List.indexOf name)
                                |> Maybe.andThen (\i -> names |> List.get (i + 1) |> Maybe.orElse (names |> List.get (i - 1)))
                                |> Maybe.orElse (names |> List.filter (\n -> n /= name) |> List.head)
                    in
                    next
                        |> Maybe.map (\nextLayout -> ( erd |> mapLayouts (Dict.remove name) |> setCurrentLayout nextLayout, Track.layoutDeleted erd.project layout ))
                        |> Maybe.withDefault ( erd, "Can't delete last layout" |> Toasts.warning |> Toast |> T.send )

                else
                    ( erd |> mapLayouts (Dict.remove name), Track.layoutDeleted erd.project layout )
            )
        |> Maybe.withDefault ( erd, "Can't find layout '" ++ name ++ "' to delete" |> Toasts.warning |> Toast |> T.send )
