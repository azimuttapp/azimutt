module PagesComponents.Projects.Id_.Updates.VirtualRelation exposing (Model, handleVirtualRelation)

import Libs.Models.Position as Position
import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (Msg(..), VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import Services.Lenses exposing (mapVirtualRelationM, setMouse, setVirtualRelation)


type alias Model x =
    { x
        | erd : Maybe Erd
        , virtualRelation : Maybe VirtualRelation
    }


handleVirtualRelation : VirtualRelationMsg -> Model x -> ( Model x, Cmd Msg )
handleVirtualRelation msg model =
    case msg of
        VRCreate ->
            ( model |> setVirtualRelation (Just { src = Nothing, mouse = Position.zero }), Cmd.none )

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
