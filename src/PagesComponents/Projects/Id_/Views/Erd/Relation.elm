module PagesComponents.Projects.Id_.Views.Erd.Relation exposing (ColumnInfo, buildColumnInfo, viewEmptyRelation, viewRelation, viewVirtualRelation)

import Components.Organisms.Relation as Relation exposing (Direction(..), RelationConf)
import Conf
import Libs.Bool as B
import Libs.List as List
import Libs.Models.Position exposing (Position)
import Libs.Tailwind exposing (Color)
import Models.Area as Area
import Models.Position as Position
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.RelationStyle exposing (RelationStyle)
import Models.Size as Size
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


viewRelation : SchemaName -> RelationStyle -> ErdConf -> Maybe ErdTableLayout -> Maybe ErdTableLayout -> ErdRelation -> Svg Msg
viewRelation defaultSchema style conf srcTable refTable relation =
    -- FIXME: all relations are always re-rendered, don't know why :(
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
                (s.table |> Area.topRightCanvasGrid |> Position.moveCanvas { dx = 0, dy = deltaTop s.index s.table.collapsed })
                    |> (\srcPos -> Relation.straight relConf ( srcPos, Left ) ( srcPos |> Position.moveCanvas { dx = 20, dy = 0 }, Right ) relation.src.nullable color label onHover)

        ( Nothing, Just r ) ->
            if r.table.collapsed then
                viewEmptyRelation

            else
                (r.table |> Area.topLeftCanvasGrid |> Position.moveCanvas { dx = 0, dy = deltaTop r.index r.table.collapsed })
                    |> (\refPos -> Relation.straight relConf ( refPos |> Position.moveCanvas { dx = -20, dy = 0 }, Left ) ( refPos, Right ) relation.src.nullable color label onHover)

        ( Just s, Just r ) ->
            let
                ( sPos, rPos ) =
                    ( s.table.position |> Position.extractCanvasGrid, r.table.position |> Position.extractCanvasGrid )

                ( ( srcX, srcDir ), ( refX, refDir ) ) =
                    positionLeft s.table r.table

                ( srcY, refY ) =
                    ( sPos.top + deltaTop s.index s.table.collapsed, rPos.top + deltaTop r.index r.table.collapsed )
            in
            Relation.show style relConf ( Position.buildCanvas { left = srcX, top = srcY }, srcDir ) ( Position.buildCanvas { left = refX, top = refY }, refDir ) relation.src.nullable color label onHover


viewVirtualRelation : RelationStyle -> ( ( Maybe ColumnInfo, ErdColumn ), Position.Canvas ) -> Svg Msg
viewVirtualRelation style ( ( maybeProps, column ), position ) =
    case maybeProps of
        Just props ->
            let
                ( pos, tablePos, tableSize ) =
                    ( position |> Position.extractCanvas, props.table.position |> Position.extractCanvasGrid, props.table.size |> Size.extractCanvas )

                isRight : Bool
                isRight =
                    pos.left > tablePos.left + tableSize.width / 2
            in
            Relation.show style
                { hover = False }
                ( props.table.position |> Position.offGrid |> Position.moveCanvas { dx = B.cond isRight tableSize.width 0, dy = deltaTop props.index props.table.collapsed }, B.cond isRight Relation.Right Relation.Left )
                ( position, B.cond isRight Relation.Left Relation.Right )
                column.nullable
                (Just props.table.color)
                "virtual relation"
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


leftCenterRight : { x | position : Position.CanvasGrid, size : Size.Canvas } -> ( Float, Float, Float )
leftCenterRight { position, size } =
    let
        pos : Position
        pos =
            position |> Position.offGrid |> Position.extractCanvas

        width : Float
        width =
            size |> Size.extractCanvas |> .width
    in
    ( pos.left, pos.left + (width / 2), pos.left + width )
