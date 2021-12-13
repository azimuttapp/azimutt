module PagesComponents.App.Views.Erd.Relation exposing (viewRelation, viewVirtualRelation)

import Conf
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color exposing (Color)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Models.ColumnRefFull exposing (ColumnRefFull)
import Models.Project.Column exposing (Column)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId
import Models.Project.TableProps exposing (TableProps)
import Models.RelationFull exposing (RelationFull)
import PagesComponents.App.Models exposing (Hover, Msg)
import PagesComponents.App.Views.Helpers exposing (withColumnName)
import Svg exposing (Svg, line, svg, text)
import Svg.Attributes exposing (class, height, strokeDasharray, style, width, x1, x2, y1, y2)


viewRelation : Hover -> RelationFull -> Svg Msg
viewRelation hover { name, src, ref } =
    case
        ( ( src.props |> M.filter (\( p, _, _ ) -> p |> .columns |> List.member src.column.name)
          , ref.props |> M.filter (\( p, _, _ ) -> p |> .columns |> List.member ref.column.name)
          )
        , ( formatText name src ref, getColor hover src ref )
        )
    of
        ( ( Nothing, Nothing ), ( label, _ ) ) ->
            svg [ class "erd-relation" ] [ text label ]

        ( ( Just ( sProps, sIndex, sSize ), Nothing ), ( label, color ) ) ->
            case { x = sProps.position.left + sSize.width, y = positionY sProps src.column } of
                srcPos ->
                    drawRelation srcPos { x = srcPos.x + 20, y = srcPos.y } src.column.nullable color (Conf.canvas.zIndex.tables + sIndex) label

        ( ( Nothing, Just ( rProps, rIndex, _ ) ), ( label, color ) ) ->
            case { x = rProps.position.left, y = positionY rProps ref.column } of
                refPos ->
                    drawRelation { x = refPos.x - 20, y = refPos.y } refPos src.column.nullable color (Conf.canvas.zIndex.tables + rIndex) label

        ( ( Just ( sProps, _, sSize ), Just ( rProps, _, rSize ) ), ( label, color ) ) ->
            case ( positionX ( sProps, sSize ) ( rProps, rSize ), ( positionY sProps src.column, positionY rProps ref.column ) ) of
                ( ( srcX, refX ), ( srcY, refY ) ) ->
                    drawRelation { x = srcX, y = srcY } { x = refX, y = refY } src.column.nullable color (Conf.canvas.zIndex.tables - 1) label


viewVirtualRelation : ( ColumnRefFull, Position ) -> Svg Msg
viewVirtualRelation ( src, pos ) =
    case src.props |> M.filter (\( p, _, _ ) -> p |> .columns |> List.member src.column.name) of
        Just ( props, _, size ) ->
            drawRelation
                { x = props.position.left + size.width, y = positionY props src.column }
                { x = pos.left, y = pos.top }
                src.column.nullable
                (Just props.color)
                (Conf.canvas.zIndex.tables - 1)
                "virtual relation"

        Nothing ->
            svg [ class "erd-relation" ] [ text "virtual relation" ]


drawRelation : Point -> Point -> Bool -> Maybe Color -> Int -> String -> Svg Msg
drawRelation src ref optional color index name =
    let
        padding : Float
        padding =
            10

        origin : Point
        origin =
            { x = min src.x ref.x - padding, y = min src.y ref.y - padding }
    in
    svg
        [ class "relation"
        , width (String.fromFloat (abs (src.x - ref.x) + (padding * 2)))
        , height (String.fromFloat (abs (src.y - ref.y) + (padding * 2)))
        , style ("position: absolute; left: " ++ String.fromFloat origin.x ++ "px; top: " ++ String.fromFloat origin.y ++ "px; z-index: " ++ String.fromInt index ++ ";")
        ]
        [ viewLine (minus src origin) (minus ref origin) optional color
        , text name
        ]


viewLine : Point -> Point -> Bool -> Maybe Color -> Svg Msg
viewLine p1 p2 optional color =
    line
        (L.prependIf optional
            (strokeDasharray "4")
            [ x1 (String.fromFloat p1.x)
            , y1 (String.fromFloat p1.y)
            , x2 (String.fromFloat p2.x)
            , y2 (String.fromFloat p2.y)
            , style
                (color
                    |> M.mapOrElse (\c -> "stroke: var(--tw-" ++ c.name ++ "); stroke-width: 3;")
                        "stroke: #A0AEC0; stroke-width: 2;"
                )
            ]
        )
        []



-- helpers


type alias Point =
    { x : Float, y : Float }


getColor : Hover -> ColumnRefFull -> ColumnRefFull -> Maybe Color
getColor hover src ref =
    (src.props |> Maybe.map (\( p, _, _ ) -> p.color))
        |> M.orElse (ref.props |> Maybe.map (\( p, _, _ ) -> p.color))
        |> M.filter (\_ -> shouldHighlight hover src || shouldHighlight hover ref)


shouldHighlight : Hover -> ColumnRefFull -> Bool
shouldHighlight hover target =
    target.props |> M.exist (\( p, _, _ ) -> p.selected || (hover.column |> M.contains target.ref))


positionX : ( TableProps, Size ) -> ( TableProps, Size ) -> ( Float, Float )
positionX srcTable refTable =
    case ( tablePositions srcTable, tablePositions refTable ) of
        ( ( srcLeft, srcCenter, srcRight ), ( refLeft, refCenter, refRight ) ) ->
            if srcRight < refLeft then
                ( srcRight, refLeft )

            else if srcCenter < refCenter then
                ( srcRight, refRight )

            else if srcLeft < refRight then
                ( srcLeft, refLeft )

            else
                ( srcLeft, refRight )


tablePositions : ( TableProps, Size ) -> ( Float, Float, Float )
tablePositions ( props, size ) =
    ( props.position.left, props.position.left + (size.width / 2), props.position.left + size.width )


headerHeight : Float
headerHeight =
    48


columnHeight : Float
columnHeight =
    31


positionY : TableProps -> Column -> Float
positionY props column =
    props.position.top + headerHeight + (columnHeight * (0.5 + (props.columns |> L.indexOf column.name |> Maybe.withDefault -1 |> toFloat)))


minus : Point -> Point -> Point
minus p1 p2 =
    { x = p1.x - p2.x, y = p1.y - p2.y }



-- formatters


formatText : RelationName -> ColumnRefFull -> ColumnRefFull -> String
formatText name src ref =
    formatRef src.table src.column ++ " -> " ++ name ++ " -> " ++ formatRef ref.table ref.column


formatRef : Table -> Column -> String
formatRef table column =
    TableId.show table.id |> withColumnName column.name
