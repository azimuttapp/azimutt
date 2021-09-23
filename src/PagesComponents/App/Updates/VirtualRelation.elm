module PagesComponents.App.Updates.VirtualRelation exposing (updateVirtualRelation)

import Libs.Position exposing (Position)
import Models.Project exposing (ColumnRef, Relation)
import PagesComponents.App.Models exposing (Model, VirtualRelation, VirtualRelationMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setProject, setRelations, setSchema)


type alias Model x y z =
    { x
        | virtualRelation : Maybe VirtualRelation
        , project : Maybe { y | schema : { z | relations : List Relation } }
    }


updateVirtualRelation : VirtualRelationMsg -> Model x y z -> Model x y z
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

                Just (Just from) ->
                    { model | virtualRelation = Nothing } |> setProject (setSchema (setRelations (\relations -> relations ++ [ buildVirtualRelation from ref ])))

        VRMove pos ->
            { model | virtualRelation = model.virtualRelation |> Maybe.map (\vr -> { vr | mouse = pos }) }

        VRCancel ->
            { model | virtualRelation = Nothing }


buildVirtualRelation : ColumnRef -> ColumnRef -> Relation
buildVirtualRelation from to =
    { name = "virtual relation", src = from, ref = to, sources = [] }
