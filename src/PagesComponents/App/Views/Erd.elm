module PagesComponents.App.Views.Erd exposing (viewErd)

import Conf exposing (conf)
import Dict exposing (Dict)
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class, id, style)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy2, lazy7)
import Libs.Html.Events exposing (onWheel)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (HtmlId, ZoomLevel)
import Libs.Ned as Ned
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Models.Project exposing (ColumnRef, ColumnRefFull, Layout, Relation, RelationFull, Schema, Table, TableId, tableIdAsHtmlId, tableIdAsString, viewportSize)
import PagesComponents.App.Models exposing (Hover, Msg(..))
import PagesComponents.App.Views.Erd.Relation exposing (viewRelation)
import PagesComponents.App.Views.Erd.Table exposing (viewTable)
import PagesComponents.App.Views.Helpers exposing (dragAttrs, sizeAttr)
import Set exposing (Set)


viewErd : Hover -> Dict HtmlId Size -> Maybe Schema -> Html Msg
viewErd hover sizes schema =
    let
        shownTableIds : Set TableId
        shownTableIds =
            schema |> Maybe.map (\s -> s.layout.tables |> List.map .id |> Set.fromList) |> Maybe.withDefault Set.empty

        shownRelations : List RelationFull
        shownRelations =
            schema |> Maybe.map (\s -> s.relations |> List.filter (\r -> Set.member r.src.table shownTableIds || Set.member r.ref.table shownTableIds) |> List.filterMap (buildRelationFull s.tables s.layout sizes)) |> Maybe.withDefault []
    in
    div ([ id conf.ids.erd, class "erd", sizeAttr (viewportSize sizes |> Maybe.withDefault (Size 0 0)), onWheel OnWheel ] ++ dragAttrs conf.ids.erd)
        [ div [ class "canvas", schema |> Maybe.map (\s -> placeAndZoom s.layout.canvas.zoom s.layout.canvas.position) |> Maybe.withDefault (placeAndZoom 1 (Position 0 0)) ]
            (schema
                |> Maybe.map
                    (\s ->
                        [ Keyed.node "div"
                            [ class "tables" ]
                            (s.layout.tables
                                |> List.reverse
                                |> L.filterZip (\t -> s.tables |> Dict.get t.id)
                                |> List.map (\( p, t ) -> ( ( t, p ), ( shownRelations |> List.filter (\r -> r.src.table.id == t.id || r.ref.table.id == t.id), sizes |> Dict.get (tableIdAsHtmlId p.id) ) ))
                                |> List.indexedMap (\i ( ( table, props ), ( rels, size ) ) -> ( tableIdAsString table.id, lazy7 viewTable hover s.layout.canvas.zoom i table props rels size ))
                            )
                        , Keyed.node "div" [ class "relations" ] (shownRelations |> List.map (\r -> ( r.name, lazy2 viewRelation hover r )))
                        ]
                    )
                |> Maybe.withDefault []
            )
        ]


placeAndZoom : ZoomLevel -> Position -> Attribute msg
placeAndZoom zoom pan =
    style "transform" ("translate(" ++ String.fromFloat pan.left ++ "px, " ++ String.fromFloat pan.top ++ "px) scale(" ++ String.fromFloat zoom ++ ")")


buildRelationFull : Dict TableId Table -> Layout -> Dict HtmlId Size -> Relation -> Maybe RelationFull
buildRelationFull tables layout sizes rel =
    Maybe.map2 (\src ref -> { name = rel.name, src = src, ref = ref, sources = rel.sources })
        (buildColumnRefFull tables layout sizes rel.src)
        (buildColumnRefFull tables layout sizes rel.ref)


buildColumnRefFull : Dict TableId Table -> Layout -> Dict HtmlId Size -> ColumnRef -> Maybe ColumnRefFull
buildColumnRefFull tables layout sizes ref =
    (tables |> Dict.get ref.table |> M.andThenZip (\table -> table.columns |> Ned.get ref.column))
        |> Maybe.map
            (\( table, column ) ->
                { ref = ref
                , table = table
                , column = column
                , props =
                    M.zip3
                        (layout.tables |> L.findBy .id ref.table)
                        (layout.tables |> L.findIndexBy .id ref.table |> Maybe.map (\i -> List.length layout.tables - 1 - i))
                        (sizes |> Dict.get (tableIdAsHtmlId ref.table))
                }
            )
