module PagesComponents.Projects.Id_.Views.Erd.Relation exposing (viewEmptyRelation, viewRelation, viewVirtualRelation)

import Components.Organisms.Relation as Relation
import Conf
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color exposing (Color)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Models.ColumnRefFull as ColumnRefFull exposing (ColumnRefFull)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableProps exposing (TableProps)
import Models.RelationFull exposing (RelationFull)
import Svg.Styled exposing (Svg, svg)
import Svg.Styled.Attributes exposing (class, height, width)


viewRelation : Maybe ColumnRef -> RelationFull -> Svg msg
viewRelation hover { name, src, ref } =
    case
        ( ( src |> computeProps, ref |> computeProps )
        , ( ColumnRefFull.format src ++ " -> " ++ name ++ " -> " ++ ColumnRefFull.format ref, getColor hover src ref )
        )
    of
        ( ( Nothing, Nothing ), _ ) ->
            viewEmptyRelation

        ( ( Just ( sProps, sIndex, sSize ), Nothing ), ( label, color ) ) ->
            case { left = sProps.position.left + sSize.width, top = positionTop sProps src.column } of
                srcPos ->
                    drawRelation srcPos { left = srcPos.left + 20, top = srcPos.top } src.column.nullable color label (Conf.canvas.zIndex.tables + sIndex)

        ( ( Nothing, Just ( rProps, rIndex, _ ) ), ( label, color ) ) ->
            case { left = rProps.position.left, top = positionTop rProps ref.column } of
                refPos ->
                    drawRelation { left = refPos.left - 20, top = refPos.top } refPos src.column.nullable color label (Conf.canvas.zIndex.tables + rIndex)

        ( ( Just ( sProps, _, sSize ), Just ( rProps, _, rSize ) ), ( label, color ) ) ->
            case ( positionLeft ( sProps, sSize ) ( rProps, rSize ), ( positionTop sProps src.column, positionTop rProps ref.column ) ) of
                ( ( srcX, refX ), ( srcY, refY ) ) ->
                    drawRelation { left = srcX, top = srcY } { left = refX, top = refY } src.column.nullable color label (Conf.canvas.zIndex.tables - 1)


viewVirtualRelation : ( ColumnRefFull, Position ) -> Svg msg
viewVirtualRelation ( src, ref ) =
    case src.props |> M.filter (\( p, _, _ ) -> p |> .columns |> List.member src.column.name) of
        Just ( props, _, size ) ->
            drawRelation
                { left = props.position.left + B.cond (ref.left < props.position.left + size.width / 2) 0 size.width
                , top = positionTop props src.column
                }
                { left = ref.left, top = ref.top }
                src.column.nullable
                (Just props.color)
                "virtual relation"
                (Conf.canvas.zIndex.tables - 1)

        Nothing ->
            viewEmptyRelation


viewEmptyRelation : Svg msg
viewEmptyRelation =
    svg [ class "erd-relation", width "0px", height "0px" ] []


computeProps : ColumnRefFull -> Maybe ( TableProps, Int, Size )
computeProps col =
    col.props |> M.filter (\( p, _, _ ) -> p |> .columns |> List.member col.column.name)


drawRelation : Position -> Position -> Bool -> Maybe Color -> String -> Int -> Svg msg
drawRelation src ref nullable color label index =
    Relation.relation
        { src = src
        , ref = ref
        , nullable = nullable
        , color = color
        , label = label
        , index = index
        }


getColor : Maybe ColumnRef -> ColumnRefFull -> ColumnRefFull -> Maybe Color
getColor hover src ref =
    (src.props |> Maybe.map (\( p, _, _ ) -> p.color))
        |> M.orElse (ref.props |> Maybe.map (\( p, _, _ ) -> p.color))
        |> M.filter (\_ -> shouldHighlight hover src || shouldHighlight hover ref)


shouldHighlight : Maybe ColumnRef -> ColumnRefFull -> Bool
shouldHighlight hover target =
    target.props |> M.any (\( p, _, _ ) -> p.selected || (hover |> M.has target.ref))


headerHeight : Float
headerHeight =
    45


columnHeight : Float
columnHeight =
    26.5


positionTop : TableProps -> Column -> Float
positionTop props column =
    props.position.top + headerHeight + (columnHeight * (0.5 + (props.columns |> L.indexOf column.name |> Maybe.withDefault -1 |> toFloat)))


positionLeft : ( TableProps, Size ) -> ( TableProps, Size ) -> ( Float, Float )
positionLeft srcTable refTable =
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
