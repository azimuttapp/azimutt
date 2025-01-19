module PagesComponents.Organization_.Project_.Updates.LinkLayout exposing (Model, handleLink)

import Libs.List as List
import Libs.Maybe as Maybe
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.Organization_.Project_.Models exposing (LinkMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout
import PagesComponents.Organization_.Project_.Models.LinkLayoutId exposing (LinkLayoutId)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty)
import Ports
import Services.Lenses exposing (mapColorT, mapErdM, mapErdMTM, mapLinks, mapLinksLT, mapLinksT, mapTargetT)
import Time
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , erdElem : ErdProps
        , dirty : Bool
        , erd : Maybe Erd
    }


handleLink : Time.Posix -> LinkMsg -> Model x -> ( Model x, Extra Msg )
handleLink now msg model =
    case msg of
        LLCreate pos layout ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> createLink now pos layout erd) ( model, Extra.none )

        LLUpdate id layout ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTMWithTime now (mapLinksLT .id id (mapTargetT (\t -> ( layout, Extra.history ( LinkMsg (LLUpdate id t), LinkMsg (LLUpdate id layout) ) ))))) |> Extra.defaultT

        LLSetColor id color ->
            model |> mapErdMTM (Erd.mapCurrentLayoutTMWithTime now (mapLinksLT .id id (mapColorT (\c -> ( color, Extra.history ( LinkMsg (LLSetColor id c), LinkMsg (LLSetColor id color) ) ))))) |> Extra.defaultT

        LLDelete id ->
            model |> deleteLink now id

        LLUnDelete index link ->
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapLinks (List.insertAt index link >> List.sortBy .id))), Ports.observeLinkSize link.id |> Extra.cmd )


createLink : Time.Posix -> Position.Grid -> LayoutName -> Erd -> Model x -> ( Model x, Extra Msg )
createLink now position layout erd model =
    ErdLayout.createLink (erd |> Erd.currentLayout) position layout
        |> (\link ->
                ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapLinks (List.append [ link ] >> List.sortBy .id)))
                , Extra.newCL [ Ports.observeLinkSize link.id, Track.linkCreated model.erd ] ( LinkMsg (LLDelete link.id), LinkMsg (LLUnDelete link.id link) )
                )
           )
        |> setDirty


deleteLink : Time.Posix -> LinkLayoutId -> Model x -> ( Model x, Extra Msg )
deleteLink now id model =
    model
        |> mapErdMTM
            (Erd.mapCurrentLayoutTWithTime now
                (mapLinksT
                    (\links ->
                        case links |> List.zipWithIndex |> List.partition (\( m, _ ) -> m.id == id) of
                            ( ( deleted, index ) :: _, kept ) ->
                                ( kept |> List.map Tuple.first, [ ( LinkMsg (LLUnDelete index deleted), LinkMsg (LLDelete deleted.id) ) ] )

                            _ ->
                                ( links, [] )
                    )
                )
            )
        |> (\( m, hist ) ->
                ( m, Extra.newHL (Track.linkDeleted model.erd) (hist |> Maybe.withDefault []) ) |> setDirty
           )
