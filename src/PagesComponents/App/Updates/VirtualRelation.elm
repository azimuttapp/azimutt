module PagesComponents.App.Updates.VirtualRelation exposing (handleVirtualRelation)

import Libs.List as L
import Libs.Models.Position as Position
import Models.Project as Project exposing (Project)
import Models.Project.Relation as Relation
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.App.Models exposing (Model, Msg, VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setProject)
import Ports exposing (getSourceId, toastInfo)


type alias Model x =
    { x
        | virtualRelation : Maybe VirtualRelation
        , project : Maybe Project
    }


handleVirtualRelation : VirtualRelationMsg -> Model x -> ( Model x, Cmd Msg )
handleVirtualRelation msg model =
    case msg of
        VRCreate ->
            ( { model | virtualRelation = Just { src = Nothing, mouse = Position.zero } }, Cmd.none )

        VRUpdate ref pos ->
            case model.virtualRelation |> Maybe.map (\{ src } -> src) of
                Nothing ->
                    ( model, Cmd.none )

                Just Nothing ->
                    ( { model | virtualRelation = Just { src = Just ref, mouse = pos } }, Cmd.none )

                Just (Just src) ->
                    case model.project |> Maybe.andThen (\p -> p.sources |> L.find (\s -> s.kind == UserDefined)) of
                        Just source ->
                            ( { model | virtualRelation = Nothing }
                                |> setProject (Project.updateSource source.id (\s -> { s | relations = s.relations ++ [ Relation.virtual src ref source.id ] }))
                            , toastInfo ("Relation added to <b>" ++ source.name ++ "</b> source.")
                            )

                        Nothing ->
                            ( { model | virtualRelation = Nothing }, getSourceId src ref )

        VRMove pos ->
            ( { model | virtualRelation = model.virtualRelation |> Maybe.map (\vr -> { vr | mouse = pos }) }, Cmd.none )

        VRCancel ->
            ( { model | virtualRelation = Nothing }, Cmd.none )
