module PagesComponents.Projects.Id_.Views.Erd.Relation exposing (ColumnInfo, buildColumnInfo, viewEmptyRelation, viewRelation, viewVirtualRelation)

import Components.Organisms.Relation as Relation exposing (Direction(..), RelationConf)
import Conf
import Libs.Bool as B
import Libs.List as List
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Tailwind exposing (Color)
import Models.Position as Position
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.SchemaName exposing (SchemaName)
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


viewRelation : SchemaName -> RelationStyle -> ErdConf -> Bool -> Maybe ErdTableLayout -> Maybe ErdTableLayout -> ErdRelation -> Svg Msg
viewRelation defaultSchema style conf dragging srcTable refTable relation =
    -- FIXME: all relations are always rendered, don't know why :(
    let
        label : String
        label =
            ErdRelation.label defaultSchema relation

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
                (s.table.position |> Position.offGrid |> Position.moveInCanvas { dx = s.table.size.width, dy = deltaTop s.index s.table.collapsed })
                    |> (\srcPos -> Relation.straight relConf ( srcPos, Left ) ( srcPos |> Position.moveInCanvas { dx = 20, dy = 0 }, Right ) relation.src.nullable color label (Conf.canvas.zIndex.tables + s.index + B.cond dragging 1000 0) onHover)

        ( Nothing, Just r ) ->
            if r.table.collapsed then
                viewEmptyRelation

            else
                (r.table.position |> Position.offGrid |> Position.moveInCanvas { dx = 0, dy = deltaTop r.index r.table.collapsed })
                    |> (\refPos -> Relation.straight relConf ( refPos |> Position.moveInCanvas { dx = -20, dy = 0 }, Left ) ( refPos, Right ) relation.src.nullable color label (Conf.canvas.zIndex.tables + r.index + B.cond dragging 1000 0) onHover)

        ( Just s, Just r ) ->
            let
                ( sPos, rPos ) =
                    ( s.table.position |> Position.extractGrid, r.table.position |> Position.extractGrid )

                ( ( srcX, srcDir ), ( refX, refDir ) ) =
                    positionLeft s.table r.table

                ( srcY, refY ) =
                    ( sPos.top + deltaTop s.index s.table.collapsed, rPos.top + deltaTop r.index r.table.collapsed )

                zIndex : Int
                zIndex =
                    Conf.canvas.zIndex.tables - 1 + min s.index r.index
            in
            Relation.show style relConf ( Position.buildInCanvas { left = srcX, top = srcY }, srcDir ) ( Position.buildInCanvas { left = refX, top = refY }, refDir ) relation.src.nullable color label zIndex onHover


viewVirtualRelation : RelationStyle -> ( ( Maybe ColumnInfo, ErdColumn ), Position.InCanvas ) -> Svg Msg
viewVirtualRelation style ( ( maybeProps, column ), position ) =
    case maybeProps of
        Just props ->
            let
                ( pos, tablePos ) =
                    ( position |> Position.extractInCanvas, props.table.position |> Position.extractGrid )

                isRight : Bool
                isRight =
                    pos.left > tablePos.left + props.table.size.width / 2
            in
            Relation.show style
                { hover = False }
                ( props.table.position |> Position.offGrid |> Position.moveInCanvas { dx = B.cond isRight props.table.size.width 0, dy = deltaTop props.index props.table.collapsed }, B.cond isRight Relation.Right Relation.Left )
                ( position, B.cond isRight Relation.Left Relation.Right )
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


deltaTop : Int -> Bool -> Float
deltaTop index collapsed =
    if collapsed then
        Conf.ui.tableHeaderHeight * 0.5

    else
        Conf.ui.tableHeaderHeight + (Conf.ui.tableColumnHeight * (0.5 + (index |> toFloat)))


positionLeft : ErdTableProps -> ErdTableProps -> ( ( Float, Relation.Direction ), ( Float, Relation.Direction ) )
positionLeft src ref =
    case ( leftCenterRight src, leftCenterRight ref ) of
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


leftCenterRight : { x | position : Position.Grid, size : Size } -> ( Float, Float, Float )
leftCenterRight { position, size } =
    let
        pos : Position
        pos =
            position |> Position.offGrid |> Position.extractInCanvas
    in
    ( pos.left, pos.left + (size.width / 2), pos.left + size.width )
