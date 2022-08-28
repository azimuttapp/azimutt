module PagesComponents.Projects.Id_.Updates.VirtualRelation exposing (Model, handleVirtualRelation)

import Libs.Task as T
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Services.Lenses exposing (mapVirtualRelationM, setMouse, setVirtualRelation)


type alias Model x =
    { x
        | erdElem : ErdProps
        , erd : Maybe Erd
        , virtualRelation : Maybe VirtualRelation
    }


handleVirtualRelation : VirtualRelationMsg -> Model x -> ( Model x, Cmd Msg )
handleVirtualRelation msg model =
    case msg of
        VRCreate src ->
            ( model |> setVirtualRelation (Just { src = src, mouse = src |> computeInitialPosition model |> Maybe.withDefault Position.zeroViewport }), Cmd.none )

        VRUpdate ref pos ->
            case model.virtualRelation |> Maybe.map .src of
                Nothing ->
                    ( model, Cmd.none )

                Just Nothing ->
                    ( model |> setVirtualRelation (Just { src = Just ref, mouse = pos }), Cmd.none )

                Just (Just src) ->
                    ( model |> setVirtualRelation Nothing, T.send (CreateRelation src ref) )

        VRMove pos ->
            ( model |> mapVirtualRelationM (setMouse pos), Cmd.none )

        VRCancel ->
            ( model |> setVirtualRelation Nothing, Cmd.none )


computeInitialPosition : Model x -> Maybe ColumnRef -> Maybe Position.Viewport
computeInitialPosition model src =
    Maybe.map2 (\c erd -> erd |> Erd.getColumnPos c |> Maybe.map (adaptPosition model erd)) src model.erd |> Maybe.andThen identity


adaptPosition : Model x -> Erd -> Position.InCanvas -> Position.Viewport
adaptPosition model erd pos =
    erd |> Erd.currentLayout |> (\l -> pos |> Position.inCanvasToViewport model.erdElem.position l.canvas.position l.canvas.zoom)
