module PagesComponents.Projects.Id_.Views.Erd.Relation exposing (viewEmptyRelation, viewRelation, viewVirtualRelation)

import Components.Organisms.Relation as Relation
import Conf
import Libs.Bool as B
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Tailwind exposing (Color)
import Models.Project.ColumnRef as ColumnRef
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (class, height, width)


viewRelation : Bool -> Maybe ErdColumnProps -> Maybe ErdColumnProps -> ErdRelation -> Svg msg
viewRelation dragging srcProps refProps relation =
    let
        label : String
        label =
            ColumnRef.show relation.src ++ " -> " ++ relation.name ++ " -> " ++ ColumnRef.show relation.ref

        color : Maybe Color
        color =
            getColor srcProps refProps
    in
    case ( srcProps, refProps ) of
        ( Nothing, Nothing ) ->
            viewEmptyRelation

        ( Just { index, position, size }, Nothing ) ->
            { left = position.left + size.width, top = positionTop position index }
                |> (\srcPos -> Relation.line srcPos { left = srcPos.left + 20, top = srcPos.top } relation.src.nullable color label (Conf.canvas.zIndex.tables + index + B.cond dragging 1000 0))

        ( Nothing, Just { index, position } ) ->
            { left = position.left, top = positionTop position index }
                |> (\refPos -> Relation.line { left = refPos.left - 20, top = refPos.top } refPos relation.src.nullable color label (Conf.canvas.zIndex.tables + index + B.cond dragging 1000 0))

        ( Just src, Just ref ) ->
            ( positionLeft src.position src.size ref.position ref.size, ( positionTop src.position src.index, positionTop ref.position ref.index ) )
                |> (\( ( srcX, refX ), ( srcY, refY ) ) -> Relation.line { left = srcX, top = srcY } { left = refX, top = refY } relation.src.nullable color label (Conf.canvas.zIndex.tables + min src.index ref.index + B.cond dragging 1000 0))


viewVirtualRelation : ( ( Maybe ErdColumnProps, ErdColumn ), Position ) -> Svg msg
viewVirtualRelation ( ( maybeProps, column ), position ) =
    case maybeProps of
        Just props ->
            Relation.line
                { left = props.position.left + B.cond (position.left < props.position.left + props.size.width / 2) 0 props.size.width
                , top = positionTop props.position props.index
                }
                { left = position.left, top = position.top }
                column.nullable
                (Just props.color)
                "virtual relation"
                (Conf.canvas.zIndex.tables - 1)

        Nothing ->
            viewEmptyRelation


viewEmptyRelation : Svg msg
viewEmptyRelation =
    svg [ class "az-empty-relation", width "0px", height "0px" ] []


getColor : Maybe ErdColumnProps -> Maybe ErdColumnProps -> Maybe Color
getColor src ref =
    case ( src, ref ) of
        ( Just s, Just r ) ->
            B.maybe (s.selected || r.selected || (s.highlighted && r.highlighted)) s.color

        ( Just s, Nothing ) ->
            B.maybe (s.selected || s.highlighted) s.color

        ( Nothing, Just r ) ->
            B.maybe (r.selected || r.highlighted) r.color

        ( Nothing, Nothing ) ->
            Nothing


positionTop : Position -> Int -> Float
positionTop position index =
    position.top + Conf.ui.tableHeaderHeight + (Conf.ui.tableColumnHeight * (0.5 + (index |> toFloat)))


positionLeft : Position -> Size -> Position -> Size -> ( Float, Float )
positionLeft srcPos srcSize refPos refSize =
    case ( tablePositions srcPos srcSize, tablePositions refPos refSize ) of
        ( ( srcLeft, srcCenter, srcRight ), ( refLeft, refCenter, refRight ) ) ->
            if srcRight < refLeft then
                ( srcRight, refLeft )

            else if srcCenter < refCenter then
                ( srcRight, refRight )

            else if srcLeft < refRight then
                ( srcLeft, refLeft )

            else
                ( srcLeft, refRight )


tablePositions : Position -> Size -> ( Float, Float, Float )
tablePositions position size =
    ( position.left, position.left + (size.width / 2), position.left + size.width )
