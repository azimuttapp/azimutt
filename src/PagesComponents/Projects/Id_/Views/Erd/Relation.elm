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

        ( Just { index, position, size, collapsed }, Nothing ) ->
            if collapsed then
                viewEmptyRelation

            else
                { left = position.left + size.width, top = positionTop position index collapsed }
                    |> (\srcPos -> Relation.line srcPos { left = srcPos.left + 20, top = srcPos.top } relation.src.nullable color label (Conf.canvas.zIndex.tables + index + B.cond dragging 1000 0))

        ( Nothing, Just { index, position, collapsed } ) ->
            if collapsed then
                viewEmptyRelation

            else
                { left = position.left, top = positionTop position index collapsed }
                    |> (\refPos -> Relation.line { left = refPos.left - 20, top = refPos.top } refPos relation.src.nullable color label (Conf.canvas.zIndex.tables + index + B.cond dragging 1000 0))

        ( Just src, Just ref ) ->
            let
                ( ( srcX, srcDir ), ( refX, refDir ) ) =
                    positionLeft src ref

                ( srcY, refY ) =
                    ( positionTop src.position src.index src.collapsed, positionTop ref.position ref.index ref.collapsed )

                zIndex : Int
                zIndex =
                    Conf.canvas.zIndex.tables - 1 + min src.index ref.index
            in
            --Relation.line { left = srcX, top = srcY } { left = refX, top = refY } relation.src.nullable color label zIndex
            Relation.curve ( { left = srcX, top = srcY }, srcDir ) ( { left = refX, top = refY }, refDir ) relation.src.nullable color label zIndex


viewVirtualRelation : ( ( Maybe ErdColumnProps, ErdColumn ), Position ) -> Svg msg
viewVirtualRelation ( ( maybeProps, column ), position ) =
    case maybeProps of
        Just props ->
            let
                isRight : Bool
                isRight =
                    position.left > props.position.left + props.size.width / 2
            in
            Relation.curve
                ( { left = props.position.left + B.cond isRight props.size.width 0, top = positionTop props.position props.index props.collapsed }, B.cond isRight Relation.Right Relation.Left )
                ( { left = position.left, top = position.top }, B.cond isRight Relation.Left Relation.Right )
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


positionTop : Position -> Int -> Bool -> Float
positionTop position index collapsed =
    if collapsed then
        position.top + Conf.ui.tableHeaderHeight * 0.5

    else
        position.top + Conf.ui.tableHeaderHeight + (Conf.ui.tableColumnHeight * (0.5 + (index |> toFloat)))


positionLeft : ErdColumnProps -> ErdColumnProps -> ( ( Float, Relation.Direction ), ( Float, Relation.Direction ) )
positionLeft src ref =
    case ( tablePositions src.position src.size, tablePositions ref.position ref.size ) of
        ( ( srcLeft, srcCenter, srcRight ), ( refLeft, refCenter, refRight ) ) ->
            (if srcRight < refLeft then
                ( ( srcRight, Relation.Right ), ( refLeft, Relation.Left ) )

             else if srcCenter < refCenter then
                ( ( srcRight, Relation.Right ), ( refRight, Relation.Right ) )

             else if srcLeft < refRight then
                ( ( srcLeft, Relation.Left ), ( refLeft, Relation.Left ) )

             else
                ( ( srcLeft, Relation.Left ), ( refRight, Relation.Right ) )
            )
                |> (\( ( srcPos, srcDir ), ( refPos, refDir ) ) ->
                        ( if src.collapsed then
                            ( srcCenter, Relation.None )

                          else
                            ( srcPos, srcDir )
                        , if ref.collapsed then
                            ( refCenter, Relation.None )

                          else
                            ( refPos, refDir )
                        )
                   )


tablePositions : Position -> Size -> ( Float, Float, Float )
tablePositions position size =
    ( position.left, position.left + (size.width / 2), position.left + size.width )
