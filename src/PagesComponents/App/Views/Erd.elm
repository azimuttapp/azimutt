module PagesComponents.App.Views.Erd exposing (viewErd)

import Conf exposing (conf)
import Dict exposing (Dict)
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class, classList, id, style)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy2, lazy6, lazy7)
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.Dict as D
import Libs.DomInfo exposing (DomInfo)
import Libs.Html.Events exposing (onWheel)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (HtmlId, ZoomLevel)
import Libs.Ned as Ned
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Models.Project exposing (CanvasProps, ColumnRef, ColumnRefFull, Relation, RelationFull, Schema, Table, TableId, TableProps, tableIdAsHtmlId, tableIdAsString, viewportSize)
import PagesComponents.App.Models exposing (CursorMode(..), DragState, Hover, Msg(..))
import PagesComponents.App.Views.Erd.Relation exposing (viewRelation)
import PagesComponents.App.Views.Erd.Table exposing (viewTable)
import PagesComponents.App.Views.Helpers exposing (dragAttrs, dragAttrs2, placeAt, size, sizeAttr)


viewErd : Hover -> CursorMode -> Maybe DragState -> Maybe Area -> Dict HtmlId DomInfo -> Maybe Schema -> Html Msg
viewErd hover cursorMode dragState selection domInfos schema =
    div
        ([ class "erd"
         , classList
            [ ( "cursor-hand", cursorMode == Drag && dragState /= Nothing )
            , ( "cursor-hand-drag", cursorMode == Drag && dragState == Nothing )
            ]
         , id conf.ids.erd
         , sizeAttr (viewportSize domInfos |> Maybe.withDefault (Size 0 0))
         , onWheel OnWheel
         ]
            ++ B.cond (cursorMode == Select) (dragAttrs2 conf.ids.erd dragState) (dragAttrs conf.ids.erd)
        )
        [ div [ class "canvas", placeAndZoom (schema |> Maybe.map (\s -> s.layout.canvas) |> Maybe.withDefault (CanvasProps (Position 0 0) 1)) ]
            (schema |> Maybe.map (\s -> viewErdContent hover selection domInfos s.layout.canvas s.layout.tables s.tables s.relations) |> Maybe.withDefault [])
        ]


viewErdContent : Hover -> Maybe Area -> Dict HtmlId DomInfo -> CanvasProps -> List TableProps -> Dict TableId Table -> List Relation -> List (Html Msg)
viewErdContent hover selection domInfos canvas layoutTables tables relations =
    let
        layoutTablesDict : Dict TableId ( TableProps, Int )
        layoutTablesDict =
            layoutTables |> L.zipWithIndex |> D.fromListMap (\( t, _ ) -> t.id)

        layoutTablesDictSize : Int
        layoutTablesDictSize =
            layoutTablesDict |> Dict.size

        shownRelations : List RelationFull
        shownRelations =
            relations
                |> List.filter (\r -> Dict.member r.src.table layoutTablesDict || Dict.member r.ref.table layoutTablesDict)
                |> List.filterMap (buildRelationFull tables layoutTablesDict layoutTablesDictSize domInfos)
    in
    [ lazy6 viewTables hover domInfos canvas.zoom layoutTables shownRelations tables
    , lazy2 viewRelations hover shownRelations
    , selection |> Maybe.map viewSelectSquare |> Maybe.withDefault (div [] [])
    ]


viewSelectSquare : Area -> Html msg
viewSelectSquare area =
    let
        pos : Position
        pos =
            Position area.left area.top

        s : Size
        s =
            Size (area.right - area.left) (area.bottom - area.top)
    in
    div ([ class "selection-area", placeAt pos ] ++ size s) []


viewTables : Hover -> Dict HtmlId DomInfo -> ZoomLevel -> List TableProps -> List RelationFull -> Dict TableId Table -> Html Msg
viewTables hover domInfos zoom layoutTables shownRelations tables =
    Keyed.node "div"
        [ class "tables" ]
        (layoutTables
            |> List.reverse
            |> L.filterZip (\t -> tables |> Dict.get t.id)
            |> List.map (\( p, t ) -> ( ( t, p ), ( shownRelations |> List.filter (\r -> r.src.table.id == t.id || r.ref.table.id == t.id), domInfos |> Dict.get (tableIdAsHtmlId p.id) ) ))
            |> List.indexedMap (\i ( ( table, props ), ( rels, domInfo ) ) -> ( tableIdAsString table.id, lazy7 viewTable hover zoom i table props rels domInfo ))
        )


viewRelations : Hover -> List RelationFull -> Html Msg
viewRelations hover shownRelations =
    Keyed.node "div" [ class "relations" ] (shownRelations |> List.map (\r -> ( r.name, lazy2 viewRelation hover r )))


placeAndZoom : CanvasProps -> Attribute msg
placeAndZoom props =
    style "transform" ("translate(" ++ String.fromFloat props.position.left ++ "px, " ++ String.fromFloat props.position.top ++ "px) scale(" ++ String.fromFloat props.zoom ++ ")")


buildRelationFull : Dict TableId Table -> Dict TableId ( TableProps, Int ) -> Int -> Dict HtmlId DomInfo -> Relation -> Maybe RelationFull
buildRelationFull tables layoutTables layoutTablesSize domInfos rel =
    Maybe.map2 (\src ref -> { name = rel.name, src = src, ref = ref, sources = rel.sources })
        (buildColumnRefFull tables layoutTables layoutTablesSize domInfos rel.src)
        (buildColumnRefFull tables layoutTables layoutTablesSize domInfos rel.ref)


buildColumnRefFull : Dict TableId Table -> Dict TableId ( TableProps, Int ) -> Int -> Dict HtmlId DomInfo -> ColumnRef -> Maybe ColumnRefFull
buildColumnRefFull tables layoutTables layoutTablesSize domInfos ref =
    (tables |> Dict.get ref.table |> M.andThenZip (\table -> table.columns |> Ned.get ref.column))
        |> Maybe.map
            (\( table, column ) ->
                { ref = ref
                , table = table
                , column = column
                , props =
                    M.zip
                        (layoutTables |> Dict.get ref.table)
                        (domInfos |> Dict.get (tableIdAsHtmlId ref.table))
                        |> Maybe.map (\( ( t, i ), d ) -> ( t, layoutTablesSize - 1 - i, d.size ))
                }
            )
