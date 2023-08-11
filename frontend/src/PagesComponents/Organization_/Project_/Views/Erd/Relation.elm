module PagesComponents.Organization_.Project_.Views.Erd.Relation exposing (ColumnInfo, buildColumnInfo, deltaTop, positionLeft, viewEmptyRelation, viewRelation, viewVirtualRelation)

import Components.Organisms.Relation as Relation
import Conf
import Libs.Bool as B
import Libs.List as List
import Libs.Models.Position exposing (Position)
import Libs.Tailwind exposing (Color)
import Models.Area as Area
import Models.Position as Position
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.RelationStyle as RelationStyle exposing (RelationStyle)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnPropsFlat)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import Svg exposing (Attribute, Svg, svg)
import Svg.Attributes exposing (class, height, strokeDasharray, width)


type alias ColumnInfo =
    { table : ErdTableProps, index : Int, highlighted : Bool }


buildColumnInfo : ColumnPath -> Maybe ErdTableLayout -> Maybe ColumnInfo
buildColumnInfo column layout =
    layout |> Maybe.andThen (\t -> t.columns |> ErdColumnProps.flatten |> List.zipWithIndex |> findColumn column |> Maybe.map (\( c, i ) -> ColumnInfo t.props i c.highlighted))


findColumn : ColumnPath -> List ( ErdColumnPropsFlat, Int ) -> Maybe ( ErdColumnPropsFlat, Int )
findColumn column columns =
    case columns |> List.findBy (Tuple.first >> .path) column of
        Just res ->
            Just res

        Nothing ->
            column |> ColumnPath.parent |> Maybe.andThen (\parent -> findColumn parent columns)


viewRelation : SchemaName -> RelationStyle -> ErdConf -> Maybe ErdTableLayout -> Maybe ErdTableLayout -> ErdRelation -> Svg Msg
viewRelation defaultSchema style conf srcTable refTable relation =
    -- TODO: all relations are always re-rendered, don't know why :(
    let
        label : String
        label =
            ErdRelation.label defaultSchema relation

        model : Relation.Model
        model =
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
                (s.table |> Area.topRightCanvasGrid |> Position.moveCanvas { dx = 0, dy = deltaTop Conf.ui.table s.index s.table.collapsed })
                    |> (\srcPos -> Relation.show RelationStyle.Straight model ( srcPos, Relation.Left ) ( srcPos |> Position.moveCanvas { dx = 20, dy = 0 }, Relation.Right ) (buildStyle relation.src.nullable) color label onHover)

        ( Nothing, Just r ) ->
            if r.table.collapsed then
                viewEmptyRelation

            else
                (r.table |> Area.topLeftCanvasGrid |> Position.moveCanvas { dx = 0, dy = deltaTop Conf.ui.table r.index r.table.collapsed })
                    |> (\refPos -> Relation.show RelationStyle.Straight model ( refPos |> Position.moveCanvas { dx = -20, dy = 0 }, Relation.Left ) ( refPos, Relation.Right ) (buildStyle relation.src.nullable) color label onHover)

        ( Just s, Just r ) ->
            let
                ( sPos, rPos ) =
                    ( s.table.position |> Position.extractGrid, r.table.position |> Position.extractGrid )

                ( ( srcX, srcDir ), ( refX, refDir ) ) =
                    positionLeft s.table r.table

                ( srcY, refY ) =
                    ( sPos.top + deltaTop Conf.ui.table s.index s.table.collapsed, rPos.top + deltaTop Conf.ui.table r.index r.table.collapsed )
            in
            Relation.show style model ( Position.canvas { left = srcX, top = srcY }, srcDir ) ( Position.canvas { left = refX, top = refY }, refDir ) (buildStyle relation.src.nullable) color label onHover


viewVirtualRelation : RelationStyle -> ( ( Maybe ColumnInfo, ErdColumn ), Position.Canvas ) -> Svg Msg
viewVirtualRelation style ( ( maybeProps, column ), position ) =
    case maybeProps of
        Just props ->
            let
                ( pos, tablePos, tableSize ) =
                    ( position |> Position.extractCanvas, props.table.position |> Position.extractGrid, props.table.size |> Size.extractCanvas )

                isRight : Bool
                isRight =
                    pos.left > tablePos.left + tableSize.width / 2
            in
            Relation.show style
                { hover = False }
                ( props.table.position |> Position.offGrid |> Position.moveCanvas { dx = B.cond isRight tableSize.width 0, dy = deltaTop Conf.ui.table props.index props.table.collapsed }, B.cond isRight Relation.Right Relation.Left )
                ( position, B.cond isRight Relation.Left Relation.Right )
                (buildStyle column.nullable)
                (Just props.table.color)
                "virtual relation"
                (\_ -> Noop "hover new virtual relation")

        Nothing ->
            viewEmptyRelation


viewEmptyRelation : Svg msg
viewEmptyRelation =
    svg [ class "az-empty-relation", width "0px", height "0px" ] []


buildStyle : Bool -> List (Attribute msg)
buildStyle nullable =
    [ strokeDasharray (B.cond nullable "4" "0") ]


getColor : Maybe ColumnInfo -> Maybe ColumnInfo -> Maybe Color
getColor src ref =
    case ( src, ref ) of
        ( Just s, Just r ) ->
            B.maybe (s.table.selected || r.table.selected || (s.highlighted && r.highlighted)) s.table.color

        ( Just s, Nothing ) ->
            B.maybe (s.table.selected || s.highlighted) s.table.color

        ( Nothing, Just r ) ->
            B.maybe (r.table.selected || r.highlighted) r.table.color

        ( Nothing, Nothing ) ->
            Nothing


positionLeft : Area.GridLike x -> Area.GridLike x -> ( ( Float, Relation.Direction ), ( Float, Relation.Direction ) )
positionLeft src ref =
    case ( leftCenterRight src, leftCenterRight ref ) of
        ( ( srcLeft, srcCenter, srcRight ), ( refLeft, refCenter, refRight ) ) ->
            if srcRight < refLeft then
                ( ( srcRight, Relation.Right ), ( refLeft, Relation.Left ) )

            else if srcCenter < refCenter then
                ( ( srcRight, Relation.Right ), ( refRight, Relation.Right ) )

            else if srcLeft < refRight then
                ( ( srcLeft, Relation.Left ), ( refLeft, Relation.Left ) )

            else
                ( ( srcLeft, Relation.Left ), ( refRight, Relation.Right ) )


leftCenterRight : Area.GridLike x -> ( Float, Float, Float )
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


deltaTop : { headerHeight : Float, columnHeight : Float } -> Int -> Bool -> Float
deltaTop conf index collapsed =
    if collapsed then
        conf.headerHeight * 0.5

    else
        conf.headerHeight + (conf.columnHeight * (0.5 + (index |> toFloat)))
