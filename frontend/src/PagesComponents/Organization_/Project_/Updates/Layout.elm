module PagesComponents.Organization_.Project_.Updates.Layout exposing (Model, handleLayout)

import Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Organization_.Project_.Models exposing (LayoutMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyM)
import Ports
import Services.Lenses exposing (mapErdMT, mapLayouts, setCurrentLayout, setLayoutOnLoad)
import Services.Toasts as Toasts
import Track


type alias Model x =
    { x | conf : ErdConf, dirty : Bool, erd : Maybe Erd }


handleLayout : LayoutMsg -> Model x -> ( Model x, Extra Msg )
handleLayout msg model =
    case msg of
        LLoad onLoad name ->
            model |> mapErdMT (loadLayout onLoad name) |> Extra.defaultT

        LDelete name ->
            model |> mapErdMT (deleteLayout name) |> setDirtyM

        LUnDelete_ name layout ->
            model |> mapErdMT (unDeleteLayout name layout) |> setDirtyM


loadLayout : String -> LayoutName -> Erd -> ( Erd, Extra Msg )
loadLayout onLoad name erd =
    (erd.layouts |> Dict.get name)
        |> Maybe.mapOrElse
            (\layout ->
                ( erd |> setCurrentLayout name |> setLayoutOnLoad onLoad
                , Extra.new
                    (Cmd.batch [ Ports.observeLayout layout, Track.layoutLoaded erd.project layout ])
                    ( LayoutMsg (LLoad onLoad erd.currentLayout), LayoutMsg (LLoad onLoad name) )
                )
            )
            ( erd, Extra.none )


deleteLayout : LayoutName -> Erd -> ( Erd, Extra Msg )
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
                        |> Maybe.map
                            (\nextLayout ->
                                ( erd |> mapLayouts (Dict.remove name) |> setCurrentLayout nextLayout
                                , Extra.new (Track.layoutDeleted erd.project layout) ( Batch [ LayoutMsg (LUnDelete_ name layout), LayoutMsg (LLoad "fit" name) ], LayoutMsg (LDelete name) )
                                )
                            )
                        |> Maybe.withDefault ( erd, "Can't delete last layout" |> Toasts.warning |> Toast |> Extra.msg )

                else
                    ( erd |> mapLayouts (Dict.remove name)
                    , Extra.new (Track.layoutDeleted erd.project layout) ( LayoutMsg (LUnDelete_ name layout), LayoutMsg (LDelete name) )
                    )
            )
        |> Maybe.withDefault ( erd, "Can't find layout '" ++ name ++ "' to delete" |> Toasts.warning |> Toast |> Extra.msg )


unDeleteLayout : LayoutName -> ErdLayout -> Erd -> ( Erd, Extra Msg )
unDeleteLayout name layout erd =
    (erd.layouts |> Dict.get name)
        |> Maybe.map (\_ -> ( erd, ( "'" ++ name ++ "' layout already exists" |> Toasts.error |> Toast |> T.send, [] ) ))
        |> Maybe.withDefault
            ( erd |> mapLayouts (Dict.insert name layout)
            , Extra.history ( Batch [ LayoutMsg (LDelete name), LayoutMsg (LLoad "fit" erd.currentLayout) ], LayoutMsg (LUnDelete_ name layout) )
            )
