module PagesComponents.App.Views.Erd exposing (viewErd)

import Conf exposing (conf)
import Dict exposing (Dict)
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class, classList, id, style)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy2, lazy6, lazy7)
import Libs.Dict as D
import Libs.Html.Events exposing (onWheel)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (HtmlId, ZoomLevel)
import Libs.Ned as Ned
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Models.Project exposing (CanvasProps, ColumnRef, ColumnRefFull, Relation, RelationFull, Schema, Table, TableId, TableProps, tableIdAsHtmlId, tableIdAsString, viewportSize)
import PagesComponents.App.Models exposing (CursorMode(..), Hover, Msg(..), SelectSquare)
import PagesComponents.App.Views.Erd.Relation exposing (viewRelation)
import PagesComponents.App.Views.Erd.Table exposing (viewTable)
import PagesComponents.App.Views.Helpers exposing (dragAttrs, placeAt, sizeAttr)


viewErd : Hover -> CursorMode -> Maybe SelectSquare -> Bool -> Dict HtmlId Size -> Maybe Schema -> Html Msg
viewErd hover cursorMode selectSquare dragging sizes schema =
    div
        ([ class "erd"
         , classList [ ( "cursor-hand", cursorMode == Drag && not dragging ), ( "cursor-hand-drag", cursorMode == Drag && dragging ) ]
         , id conf.ids.erd
         , sizeAttr (viewportSize sizes |> Maybe.withDefault (Size 0 0))
         , onWheel OnWheel
         ]
            ++ dragAttrs conf.ids.erd
        )
        [ div [ class "canvas", placeAndZoom (schema |> Maybe.map (\s -> s.layout.canvas) |> Maybe.withDefault (CanvasProps (Position 0 0) 1)) ]
            (schema |> Maybe.map (\s -> viewErdContent hover selectSquare sizes s.layout.canvas.zoom s.layout.tables s.tables s.relations) |> Maybe.withDefault [])
        ]


viewErdContent : Hover -> Maybe SelectSquare -> Dict HtmlId Size -> ZoomLevel -> List TableProps -> Dict TableId Table -> List Relation -> List (Html Msg)
viewErdContent hover selectSquare sizes zoom layoutTables tables relations =
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
                |> List.filterMap (buildRelationFull tables layoutTablesDict layoutTablesDictSize sizes)
    in
    [ lazy6 viewTables hover sizes zoom layoutTables shownRelations tables
    , lazy2 viewRelations hover shownRelations
    , selectSquare |> Maybe.map viewSelectSquare |> Maybe.withDefault (div [] [])
    ]


viewSelectSquare : SelectSquare -> Html msg
viewSelectSquare selectSquare =
    let
        ( top, height ) =
            if selectSquare.size.height > 0 then
                ( selectSquare.topLeft.top, selectSquare.size.height )

            else
                ( selectSquare.topLeft.top + selectSquare.size.height, -selectSquare.size.height )

        ( left, width ) =
            if selectSquare.size.width > 0 then
                ( selectSquare.topLeft.left, selectSquare.size.width )

            else
                ( selectSquare.topLeft.left + selectSquare.size.width, -selectSquare.size.width )
    in
    div [ placeAt (Position left top), style "width" (String.fromFloat width ++ "px"), style "height" (String.fromFloat height ++ "px"), style "background" "red" ] []


viewTables : Hover -> Dict HtmlId Size -> ZoomLevel -> List TableProps -> List RelationFull -> Dict TableId Table -> Html Msg
viewTables hover sizes zoom layoutTables shownRelations tables =
    Keyed.node "div"
        [ class "tables" ]
        (layoutTables
            |> List.reverse
            |> L.filterZip (\t -> tables |> Dict.get t.id)
            |> List.map (\( p, t ) -> ( ( t, p ), ( shownRelations |> List.filter (\r -> r.src.table.id == t.id || r.ref.table.id == t.id), sizes |> Dict.get (tableIdAsHtmlId p.id) ) ))
            |> List.indexedMap (\i ( ( table, props ), ( rels, size ) ) -> ( tableIdAsString table.id, lazy7 viewTable hover zoom i table props rels size ))
        )


viewRelations : Hover -> List RelationFull -> Html Msg
viewRelations hover shownRelations =
    Keyed.node "div" [ class "relations" ] (shownRelations |> List.map (\r -> ( r.name, lazy2 viewRelation hover r )))


placeAndZoom : CanvasProps -> Attribute msg
placeAndZoom props =
    style "transform" ("translate(" ++ String.fromFloat props.position.left ++ "px, " ++ String.fromFloat props.position.top ++ "px) scale(" ++ String.fromFloat props.zoom ++ ")")


buildRelationFull : Dict TableId Table -> Dict TableId ( TableProps, Int ) -> Int -> Dict HtmlId Size -> Relation -> Maybe RelationFull
buildRelationFull tables layoutTables layoutTablesSize sizes rel =
    Maybe.map2 (\src ref -> { name = rel.name, src = src, ref = ref, sources = rel.sources })
        (buildColumnRefFull tables layoutTables layoutTablesSize sizes rel.src)
        (buildColumnRefFull tables layoutTables layoutTablesSize sizes rel.ref)


buildColumnRefFull : Dict TableId Table -> Dict TableId ( TableProps, Int ) -> Int -> Dict HtmlId Size -> ColumnRef -> Maybe ColumnRefFull
buildColumnRefFull tables layoutTables layoutTablesSize sizes ref =
    (tables |> Dict.get ref.table |> M.andThenZip (\table -> table.columns |> Ned.get ref.column))
        |> Maybe.map
            (\( table, column ) ->
                { ref = ref
                , table = table
                , column = column
                , props =
                    M.zip
                        (layoutTables |> Dict.get ref.table)
                        (sizes |> Dict.get (tableIdAsHtmlId ref.table))
                        |> Maybe.map (\( ( t, i ), s ) -> ( t, layoutTablesSize - 1 - i, s ))
                }
            )
