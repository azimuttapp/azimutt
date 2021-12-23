module PagesComponents.Projects.Id_.Views.Erd exposing (Model, viewErd)

import Conf
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, main_)
import Html.Styled.Attributes exposing (class, classList, css, id)
import Html.Styled.Keyed as Keyed
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.Dict as D
import Libs.DomInfo exposing (DomInfo)
import Libs.Html.Styled.Attributes exposing (onPointerDownStopPropagation)
import Libs.Html.Styled.Events exposing (onWheel)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.Tailwind.Utilities as Tu
import Models.ColumnRefFull exposing (ColumnRefFull)
import Models.Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.RelationFull as RelationFull exposing (RelationFull)
import Models.TableFull exposing (TableFull)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), DragState, Msg(..), VirtualRelation)
import PagesComponents.Projects.Id_.Updates.Drag as Drag
import PagesComponents.Projects.Id_.Views.Erd.Relation exposing (viewRelation, viewVirtualRelation)
import PagesComponents.Projects.Id_.Views.Erd.Table exposing (viewTable)
import Svg.Styled exposing (svg)
import Tailwind.Utilities as Tw


type alias Model x =
    { x
        | cursorMode : CursorMode
        , selectionBox : Maybe Area
        , virtualRelation : Maybe VirtualRelation
        , domInfos : Dict HtmlId DomInfo
        , openedDropdown : HtmlId
        , dragging : Maybe DragState
        , hoverTable : Maybe TableId
        , hoverColumn : Maybe ColumnRef
    }


viewErd : Theme -> Model x -> Project -> Html Msg
viewErd _ model project =
    let
        shownTables : Dict TableId TableFull
        shownTables =
            project.layout.tables |> List.reverse |> L.zipWithIndex |> List.filterMap (\( props, i ) -> project.tables |> Dict.get props.id |> Maybe.map (\t -> TableFull t.id i t props)) |> D.fromListMap .id

        shownRelations : List RelationFull
        shownRelations =
            project.relations
                |> List.filter (\r -> Dict.member r.src.table shownTables || Dict.member r.ref.table shownTables)
                |> List.filterMap (buildRelationFull project.tables shownTables model.domInfos)

        virtualRelation : Maybe ( ColumnRefFull, Position )
        virtualRelation =
            model.virtualRelation
                |> Maybe.andThen
                    (\vr ->
                        vr.src
                            |> Maybe.andThen (buildColumnRefFull project.tables shownTables model.domInfos)
                            |> Maybe.map (\ref -> ( ref, vr.mouse |> CanvasProps.adapt project.layout.canvas model.domInfos ))
                    )

        position : Position
        position =
            project.layout.canvas.position |> (\pos -> model.dragging |> M.filter (\d -> d.id == Conf.ids.erd) |> M.mapOrElse (\d -> pos |> Drag.move d 1) pos)
    in
    main_
        [ class "tw-erd"
        , classList
            [ ( "tw-cursor-hand", model.cursorMode == CursorDrag && model.dragging == Nothing && model.virtualRelation == Nothing )
            , ( "tw-cursor-hand-drag", model.cursorMode == CursorDrag && model.dragging /= Nothing && model.virtualRelation == Nothing )
            , ( "tw-cursor-cross", model.virtualRelation /= Nothing )
            ]
        , id Conf.ids.erd
        , onWheel OnWheel
        , onPointerDownStopPropagation (DragStart (B.cond (model.cursorMode == CursorDrag) Conf.ids.erd Conf.ids.selectionBox))
        ]
        [ div [ class "tw-canvas", css [ Tw.transform, Tw.origin_top_left, Tu.translate_x_y position.left position.top "px", Tu.scale project.layout.canvas.zoom ] ]
            [ shownRelations |> viewRelations model.dragging project.layout.canvas.zoom model.hoverColumn
            , shownTables |> viewTables model project.layout.canvas.zoom shownRelations
            , model.selectionBox |> M.mapOrElse viewSelectionBox (div [] [])
            , virtualRelation |> M.mapOrElse viewVirtualRelation (svg [] [])
            ]
        ]


viewTables : Model x -> ZoomLevel -> List RelationFull -> Dict TableId TableFull -> Html Msg
viewTables model zoom relations tables =
    Keyed.node "div"
        [ class "tables" ]
        (tables
            |> Dict.values
            |> L.zipWith (\table -> ( model.domInfos |> Dict.get (TableId.toHtmlId table.id), relations |> List.filter (RelationFull.hasTableLink table.id) ))
            |> List.map (\( table, ( domInfos, tableRelations ) ) -> ( TableId.toString table.id, viewTable model zoom table domInfos tableRelations ))
        )


viewRelations : Maybe DragState -> ZoomLevel -> Maybe ColumnRef -> List RelationFull -> Html Msg
viewRelations dragging zoom hover relations =
    Keyed.node "div" [ class "relations" ] (relations |> List.map (\r -> ( r.name, viewRelation dragging zoom hover r )))


viewSelectionBox : Area -> Html Msg
viewSelectionBox area =
    div
        [ class "tw-selection-area"
        , css
            [ Tw.transform
            , Tu.translate_x_y area.position.left area.position.top "px"
            , Tu.w area.size.width "px"
            , Tu.h area.size.height "px"
            , Color.border Color.teal 400
            , Tw.border_2
            , Color.bg Color.teal 400
            , Tw.bg_opacity_25
            ]
        ]
        []



-- HELPERS


buildRelationFull : Dict TableId Table -> Dict TableId TableFull -> Dict HtmlId DomInfo -> Relation -> Maybe RelationFull
buildRelationFull allTables layoutTables domInfos rel =
    Maybe.map2 (\src ref -> { name = rel.name, src = src, ref = ref, origins = rel.origins })
        (rel.src |> buildColumnRefFull allTables layoutTables domInfos)
        (rel.ref |> buildColumnRefFull allTables layoutTables domInfos)


buildColumnRefFull : Dict TableId Table -> Dict TableId TableFull -> Dict HtmlId DomInfo -> ColumnRef -> Maybe ColumnRefFull
buildColumnRefFull allTables layoutTables domInfos ref =
    (allTables |> Dict.get ref.table |> M.andThenZip (\table -> table.columns |> Ned.get ref.column))
        |> Maybe.map
            (\( table, column ) ->
                { ref = ref
                , table = table
                , column = column
                , props =
                    M.zip
                        (layoutTables |> Dict.get ref.table)
                        (domInfos |> Dict.get (TableId.toHtmlId ref.table))
                        |> Maybe.map (\( t, d ) -> ( t.props, t.index, d.size ))
                }
            )
