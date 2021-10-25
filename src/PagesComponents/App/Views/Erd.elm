module PagesComponents.App.Views.Erd exposing (viewErd)

import Conf exposing (conf)
import Dict exposing (Dict)
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class, classList, id, style)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy2, lazy7, lazy8)
import Libs.Area exposing (Area)
import Libs.Dict as D
import Libs.DomInfo exposing (DomInfo)
import Libs.Html.Events exposing (onWheel)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (ZoomLevel)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Models.Project exposing (CanvasProps, ColumnRef, ColumnRefFull, Project, Relation, RelationFull, Table, TableProps, viewportSize)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.App.Helpers exposing (pagePosToCanvasPos)
import PagesComponents.App.Models exposing (CursorMode(..), DragState, Hover, Msg(..), VirtualRelation)
import PagesComponents.App.Views.Erd.Relation exposing (viewRelation, viewVirtualRelation)
import PagesComponents.App.Views.Erd.Table exposing (viewTable)
import PagesComponents.App.Views.Helpers exposing (onDrag, placeAt, size, sizeAttr)


viewErd : Hover -> CursorMode -> Maybe DragState -> Maybe VirtualRelation -> Maybe Area -> Dict HtmlId DomInfo -> Maybe Project -> Html Msg
viewErd hover cursorMode dragState virtualRelation selection domInfos project =
    div
        [ class "erd"
        , classList
            [ ( "cursor-hand", cursorMode == Drag && dragState == Nothing && virtualRelation == Nothing )
            , ( "cursor-hand-drag", cursorMode == Drag && dragState /= Nothing && virtualRelation == Nothing )
            , ( "cursor-cross", virtualRelation /= Nothing )
            ]
        , id conf.ids.erd
        , sizeAttr (viewportSize domInfos |> Maybe.withDefault (Size 0 0))
        , onWheel OnWheel
        , onDrag conf.ids.erd
        ]
        [ div [ class "canvas", placeAndZoom (project |> M.mapOrElse (.layout >> .canvas) (CanvasProps (Position 0 0) 1)) ]
            (project |> M.mapOrElse (\p -> viewErdContent hover virtualRelation selection domInfos p) [])
        ]


viewErdContent : Hover -> Maybe VirtualRelation -> Maybe Area -> Dict HtmlId DomInfo -> Project -> List (Html Msg)
viewErdContent hover virtualRelation selection domInfos project =
    let
        layoutTablesDict : Dict TableId ( TableProps, Int )
        layoutTablesDict =
            project.layout.tables |> L.zipWithIndex |> D.fromListMap (\( t, _ ) -> t.id)

        layoutTablesDictSize : Int
        layoutTablesDictSize =
            layoutTablesDict |> Dict.size

        shownRelations : List RelationFull
        shownRelations =
            project.relations
                |> List.filter (\r -> Dict.member r.src.table layoutTablesDict || Dict.member r.ref.table layoutTablesDict)
                |> List.filterMap (buildRelationFull project.tables layoutTablesDict layoutTablesDictSize domInfos)

        virtualRelationShown : Maybe ( ColumnRefFull, Position )
        virtualRelationShown =
            virtualRelation
                |> Maybe.andThen
                    (\vr ->
                        vr.src
                            |> Maybe.andThen (buildColumnRefFull project.tables layoutTablesDict layoutTablesDictSize domInfos)
                            |> Maybe.map (\ref -> ( ref, vr.mouse |> pagePosToCanvasPos domInfos project.layout.canvas ))
                    )
    in
    [ lazy7 viewTables hover virtualRelation domInfos project.layout.canvas.zoom project.layout.tables shownRelations project.tables
    , lazy2 viewRelations hover shownRelations
    , selection |> M.mapOrElse viewSelectSquare (div [] [])
    , virtualRelationShown |> M.mapOrElse viewVirtualRelation (div [] [])
    ]


viewSelectSquare : Area -> Html msg
viewSelectSquare area =
    div ([ class "selection-area", placeAt area.position ] ++ size area.size) []


viewTables : Hover -> Maybe VirtualRelation -> Dict HtmlId DomInfo -> ZoomLevel -> List TableProps -> List RelationFull -> Dict TableId Table -> Html Msg
viewTables hover virtualRelation domInfos zoom layoutTables shownRelations tables =
    Keyed.node "div"
        [ class "tables" ]
        (layoutTables
            |> List.reverse
            |> L.filterZip (\t -> tables |> Dict.get t.id)
            |> List.map (\( p, t ) -> ( ( t, p ), ( shownRelations |> List.filter (\r -> r.src.table.id == t.id || r.ref.table.id == t.id), domInfos |> Dict.get (TableId.asHtmlId p.id) ) ))
            |> List.indexedMap (\i ( ( table, props ), ( rels, domInfo ) ) -> ( TableId.asString table.id, lazy8 viewTable hover virtualRelation zoom i table props rels domInfo ))
        )


viewRelations : Hover -> List RelationFull -> Html Msg
viewRelations hover shownRelations =
    Keyed.node "div" [ class "relations" ] (shownRelations |> List.map (\r -> ( r.name, lazy2 viewRelation hover r )))


placeAndZoom : CanvasProps -> Attribute msg
placeAndZoom props =
    style "transform" ("translate(" ++ String.fromFloat props.position.left ++ "px, " ++ String.fromFloat props.position.top ++ "px) scale(" ++ String.fromFloat props.zoom ++ ")")


buildRelationFull : Dict TableId Table -> Dict TableId ( TableProps, Int ) -> Int -> Dict HtmlId DomInfo -> Relation -> Maybe RelationFull
buildRelationFull tables layoutTables layoutTablesSize domInfos rel =
    Maybe.map2 (\src ref -> { name = rel.name, src = src, ref = ref, origins = rel.origins })
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
                        (domInfos |> Dict.get (TableId.asHtmlId ref.table))
                        |> Maybe.map (\( ( t, i ), d ) -> ( t, layoutTablesSize - 1 - i, d.size ))
                }
            )
