module PagesComponents.App.Updates.VirtualRelation exposing (updateVirtualRelation)

import Libs.List as L
import Libs.Position exposing (Position)
import Models.Project as Project exposing (Project)
import Models.Project.Relation as Relation
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.App.Models exposing (Model, Msg, VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setProject, setRelations)
import Ports exposing (toastInfo)


type alias Model x =
    { x
        | virtualRelation : Maybe VirtualRelation
        , project : Maybe Project
    }


updateVirtualRelation : VirtualRelationMsg -> Model x -> ( Model x, Cmd Msg )
updateVirtualRelation msg model =
    case msg of
        VRCreate ->
            ( { model | virtualRelation = Just { src = Nothing, mouse = Position 0 0 } }, Cmd.none )

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
                            , toastInfo ("Relation added to " ++ source.name ++ " source.")
                            )

                        Nothing ->
                            ( { model | virtualRelation = Nothing }
                                |> setProject (setRelations (\relations -> relations ++ [ Relation.virtual src ref (SourceId.new "TODO") ]))
                            , Cmd.none
                            )

        VRMove pos ->
            ( { model | virtualRelation = model.virtualRelation |> Maybe.map (\vr -> { vr | mouse = pos }) }, Cmd.none )

        VRCancel ->
            ( { model | virtualRelation = Nothing }, Cmd.none )
