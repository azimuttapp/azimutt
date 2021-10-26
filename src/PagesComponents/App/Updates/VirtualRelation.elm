module PagesComponents.App.Updates.VirtualRelation exposing (updateVirtualRelation)

import Libs.Position exposing (Position)
import Models.Project.Relation as Relation exposing (Relation)
import PagesComponents.App.Models exposing (Model, VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setProject, setRelations)


type alias Model x y =
    { x
        | virtualRelation : Maybe VirtualRelation
        , project : Maybe { y | relations : List Relation }
    }


updateVirtualRelation : VirtualRelationMsg -> Model x y -> Model x y
updateVirtualRelation msg model =
    case msg of
        VRCreate ->
            { model | virtualRelation = Just { src = Nothing, mouse = Position 0 0 } }

        VRUpdate ref pos ->
            case model.virtualRelation |> Maybe.map (\{ src } -> src) of
                Nothing ->
                    model

                Just Nothing ->
                    { model | virtualRelation = Just { src = Just ref, mouse = pos } }

                Just (Just src) ->
                    { model | virtualRelation = Nothing } |> setProject (setRelations (\relations -> relations ++ [ Relation.build "virtual relation" src ref [] ]))

        VRMove pos ->
            { model | virtualRelation = model.virtualRelation |> Maybe.map (\vr -> { vr | mouse = pos }) }

        VRCancel ->
            { model | virtualRelation = Nothing }
