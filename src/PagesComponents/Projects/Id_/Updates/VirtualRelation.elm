module PagesComponents.Projects.Id_.Updates.VirtualRelation exposing (Model, handleVirtualRelation)

import Libs.List as List
import Libs.Models.Position as Position
import Libs.Task as T
import Models.Project.Relation as Relation
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.Projects.Id_.Models exposing (Msg, VirtualRelation, VirtualRelationMsg(..), toastInfo)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapErdM, mapRelations, mapVirtualRelationM, setMouse, setVirtualRelation)


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
                    case model.erd |> Maybe.andThen (\p -> p.sources |> List.find (\s -> s.kind == UserDefined)) of
                        Just source ->
                            ( model
                                |> setVirtualRelation Nothing
                                |> mapErdM (Erd.mapSource source.id (mapRelations (\relations -> relations ++ [ Relation.virtual src ref source.id ])))
                            , T.send (toastInfo ("Relation added to " ++ source.name ++ " source."))
                            )

                        Nothing ->
                            ( model |> setVirtualRelation Nothing, Ports.getSourceId src ref )

        VRMove pos ->
            ( model |> mapVirtualRelationM (setMouse pos), Cmd.none )

        VRCancel ->
            ( model |> setVirtualRelation Nothing, Cmd.none )
