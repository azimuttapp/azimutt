module PagesComponents.Projects.Id_.Views.Erd.Relation exposing (ColumnInfo, buildColumnInfo, viewEmptyRelation, viewRelation, viewVirtualRelation)

import Components.Organisms.Relation as Relation exposing (Direction(..), RelationConf)
import Conf
import Libs.Bool as B
import Libs.List as List
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Tailwind exposing (Color)
import Models.Project.ColumnName exposing (ColumnName)
import Models.RelationStyle exposing (RelationStyle)
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps)
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (class, height, width)


type alias ColumnInfo =
    { table : ErdTableProps, column : ErdColumnProps, index : Int }


buildColumnInfo : ColumnName -> Maybe ErdTableLayout -> Maybe ColumnInfo
buildColumnInfo column layout =
    layout |> Maybe.andThen (\t -> t.columns |> List.zipWithIndex |> List.findBy (Tuple.first >> .name) column |> Maybe.map (\( c, i ) -> ColumnInfo t.props c i))


viewRelation : RelationStyle -> ErdConf -> Bool -> Maybe ErdTableLayout -> Maybe ErdTableLayout -> ErdRelation -> Svg Msg
viewRelation style conf dragging srcTable refTable relation =
    -- FIXME: all relations are always rendered, don't know why :(
    let
        label : String
        label =
            ErdRelation.label relation

        relConf : RelationConf
        relConf =
            { hover = conf.hover }

        ( src, ref ) =
            ( srcTable |> buildColumnInfo relation.src.column, refTable |> buildColumnInfo relation.ref.column )

        color : Maybe Color
        color =
            getColor src ref

        onHover : Bool -> Msg
        onHover =
            ToggleHoverColumn { table = relation.src.table, column = relation.src.column }
    in
    case ( src, ref ) of
        ( Nothing, Nothing ) ->
            viewEmptyRelation

        ( Just s, Nothing ) ->
            if s.table.collapsed then
                viewEmptyRelation

            else
                { left = s.table.position.left + s.table.size.width, top = positionTop s.table.position s.index s.table.collapsed }
                    |> (\srcPos -> Relation.straight relConf ( srcPos, Left ) ( { left = srcPos.left + 20, top = srcPos.top }, Right ) relation.src.nullable color label (Conf.canvas.zIndex.tables + s.index + B.cond dragging 1000 0) onHover)

        ( Nothing, Just r ) ->
            if r.table.collapsed then
                viewEmptyRelation

            else
                { left = r.table.position.left, top = positionTop r.table.position r.index r.table.collapsed }
                    |> (\refPos -> Relation.straight relConf ( { left = refPos.left - 20, top = refPos.top }, Left ) ( refPos, Right ) relation.src.nullable color label (Conf.canvas.zIndex.tables + r.index + B.cond dragging 1000 0) onHover)

        ( Just s, Just r ) ->
            let
                ( ( srcX, srcDir ), ( refX, refDir ) ) =
                    positionLeft s.table r.table

                ( srcY, refY ) =
                    ( positionTop s.table.position s.index s.table.collapsed, positionTop r.table.position r.index r.table.collapsed )

                zIndex : Int
                zIndex =
                    Conf.canvas.zIndex.tables - 1 + min s.index r.index
            in
            Relation.show style relConf ( { left = srcX, top = srcY }, srcDir ) ( { left = refX, top = refY }, refDir ) relation.src.nullable color label zIndex onHover


viewVirtualRelation : RelationStyle -> ( ( Maybe ColumnInfo, ErdColumn ), Position ) -> Svg Msg
viewVirtualRelation style ( ( maybeProps, column ), position ) =
    case maybeProps of
        Just props ->
            let
                isRight : Bool
                isRight =
                    position.left > props.table.position.left + props.table.size.width / 2
            in
            Relation.show style
                { hover = False }
                ( { left = props.table.position.left + B.cond isRight props.table.size.width 0, top = positionTop props.table.position props.index props.table.collapsed }, B.cond isRight Relation.Right Relation.Left )
                ( { left = position.left, top = position.top }, B.cond isRight Relation.Left Relation.Right )
                column.nullable
                (Just props.table.color)
                "virtual relation"
                (Conf.canvas.zIndex.tables - 1)
                (\_ -> Noop "hover new virtual relation")

        Nothing ->
            viewEmptyRelation


viewEmptyRelation : Svg msg
viewEmptyRelation =
    svg [ class "az-empty-relation", width "0px", height "0px" ] []


getColor : Maybe ColumnInfo -> Maybe ColumnInfo -> Maybe Color
getColor src ref =
    case ( src, ref ) of
        ( Just s, Just r ) ->
            B.maybe (s.table.selected || r.table.selected || (s.column.highlighted && r.column.highlighted)) s.table.color

        ( Just s, Nothing ) ->
            B.maybe (s.table.selected || s.column.highlighted) s.table.color

        ( Nothing, Just r ) ->
            B.maybe (r.table.selected || r.column.highlighted) r.table.color

        ( Nothing, Nothing ) ->
            Nothing


positionTop : Position -> Int -> Bool -> Float
positionTop position index collapsed =
    if collapsed then
        position.top + Conf.ui.tableHeaderHeight * 0.5

    else
        position.top + Conf.ui.tableHeaderHeight + (Conf.ui.tableColumnHeight * (0.5 + (index |> toFloat)))


positionLeft : ErdTableProps -> ErdTableProps -> ( ( Float, Relation.Direction ), ( Float, Relation.Direction ) )
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
