module PagesComponents.Organization_.Project_.Updates.VirtualRelation exposing (Model, handleVirtualRelation)

import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Lenses exposing (mapVirtualRelationM, setMouse, setVirtualRelation)


type alias Model x =
    { x
        | erdElem : ErdProps
        , erd : Maybe Erd
        , virtualRelation : Maybe VirtualRelation
    }


handleVirtualRelation : VirtualRelationMsg -> Model x -> ( Model x, Extra Msg )
handleVirtualRelation msg model =
    case msg of
        VRCreate src ->
            ( model |> setVirtualRelation (Just { src = src, mouse = src |> computeInitialPosition model |> Maybe.withDefault Position.zeroViewport }), Extra.none )

        VRUpdate ref pos ->
            case model.virtualRelation |> Maybe.map .src of
                Nothing ->
                    ( model, Extra.none )

                Just Nothing ->
                    ( model |> setVirtualRelation (Just { src = Just ref, mouse = pos }), Extra.none )

                Just (Just src) ->
                    ( model |> setVirtualRelation Nothing, CreateRelations [ { src = src, ref = ref } ] |> Extra.msg )

        VRMove pos ->
            ( model |> mapVirtualRelationM (setMouse pos), Extra.none )

        VRCancel ->
            ( model |> setVirtualRelation Nothing, Extra.none )


computeInitialPosition : Model x -> Maybe ColumnRef -> Maybe Position.Viewport
computeInitialPosition model src =
    Maybe.map2 (\c erd -> erd |> Erd.getColumnPos c |> Maybe.map (adaptPosition model erd)) src model.erd |> Maybe.andThen identity


adaptPosition : Model x -> Erd -> Position.Canvas -> Position.Viewport
adaptPosition model erd pos =
    erd |> Erd.currentLayout |> (\l -> pos |> Position.canvasToViewport model.erdElem.position l.canvas.position l.canvas.zoom)
