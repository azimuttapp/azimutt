module PagesComponents.Projects.Id_.Views.Erd exposing (Model, viewErd)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Conf
import Css
import Dict exposing (Dict)
import Html.Styled exposing (Html, button, div, h2, main_, p, text)
import Html.Styled.Attributes exposing (class, classList, css, id)
import Html.Styled.Events exposing (onClick)
import Html.Styled.Keyed as Keyed
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.Dict as D
import Libs.Html.Styled exposing (bText, extLink, sendTweet)
import Libs.Html.Styled.Events exposing (onWheel, stopPointerDown)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size as Size
import Libs.Models.Theme exposing (Theme)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.String as S
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
import PagesComponents.Projects.Id_.Views.Erd.Relation exposing (viewEmptyRelation, viewRelation, viewVirtualRelation)
import PagesComponents.Projects.Id_.Views.Erd.Table exposing (viewTable)
import Tailwind.Utilities as Tw


type alias Model x =
    { x
        | cursorMode : CursorMode
        , selectionBox : Maybe Area
        , virtualRelation : Maybe VirtualRelation
        , openedDropdown : HtmlId
        , dragging : Maybe DragState
        , hoverTable : Maybe TableId
        , hoverColumn : Maybe ColumnRef
    }


viewErd : Theme -> Model x -> Project -> Html Msg
viewErd theme model project =
    let
        layoutTables : Dict TableId TableFull
        layoutTables =
            project.layout.tables |> List.reverse |> L.zipWithIndex |> List.filterMap (\( props, i ) -> project.tables |> Dict.get props.id |> Maybe.map (\t -> TableFull t.id i t props)) |> D.fromListMap .id

        shownTables : Dict TableId TableFull
        shownTables =
            layoutTables |> Dict.filter (\_ t -> t.props.size /= Size.zero)

        shownRelations : List RelationFull
        shownRelations =
            project.relations
                |> List.filter (\r -> [ r.src, r.ref ] |> List.any (\c -> shownTables |> Dict.member c.table))
                |> List.filterMap (buildRelationFull project.tables shownTables)

        virtualRelation : Maybe ( ColumnRefFull, Position )
        virtualRelation =
            model.virtualRelation
                |> Maybe.andThen
                    (\vr ->
                        vr.src
                            |> Maybe.andThen (buildColumnRefFull project.tables shownTables)
                            |> Maybe.map (\ref -> ( ref, vr.mouse |> CanvasProps.adapt project.layout.canvas Dict.empty ))
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
        , stopPointerDown (.position >> DragStart (B.cond (model.cursorMode == CursorDrag) Conf.ids.erd Conf.ids.selectionBox))
        ]
        [ div [ class "tw-canvas", css [ Tw.transform, Tw.origin_top_left, Tu.translate_x_y position.left position.top "px", Tu.scale project.layout.canvas.zoom ] ]
            [ layoutTables |> viewTables model project.layout.canvas.zoom shownRelations
            , shownRelations |> viewRelations model.dragging project.layout.canvas.zoom model.hoverColumn
            , model.selectionBox |> M.filter (\_ -> project.layout.tables |> L.nonEmpty) |> M.mapOrElse viewSelectionBox (div [] [])
            , virtualRelation |> M.mapOrElse viewVirtualRelation viewEmptyRelation
            ]
        , if project.layout.tables |> List.isEmpty then
            viewEmptyState theme project.tables

          else
            div [] []
        ]


viewTables : Model x -> ZoomLevel -> List RelationFull -> Dict TableId TableFull -> Html Msg
viewTables model zoom relations tables =
    Keyed.node "div"
        [ class "tw-tables" ]
        (tables
            |> Dict.values
            |> L.zipWith (\table -> relations |> List.filter (RelationFull.hasTableLink table.id))
            |> List.map (\( table, tableRelations ) -> ( TableId.toString table.id, viewTable model zoom table tableRelations ))
        )


viewRelations : Maybe DragState -> ZoomLevel -> Maybe ColumnRef -> List RelationFull -> Html Msg
viewRelations dragging zoom hover relations =
    Keyed.node "div" [ class "tw-relations" ] (relations |> List.map (\r -> ( r.name, viewRelation dragging zoom hover r )))


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


viewEmptyState : Theme -> Dict TableId Table -> Html Msg
viewEmptyState theme tables =
    let
        bestTables : List Table
        bestTables =
            tables
                |> Dict.values
                |> L.filterNot (\t -> (t.schema |> String.contains "_") || (t.name |> String.contains "_") || (t.schema |> String.contains "-") || (t.name |> String.contains "-"))
                |> List.sortBy (\t -> (t.name |> String.length) - (t.columns |> Ned.size))
                |> List.take 10
    in
    div [ css [ Tw.flex, Tw.h_full, Tw.justify_center, Tw.items_center ] ]
        [ div [ css [ Tw.max_w_prose, Tw.p_6, Tw.bg_white, Tw.border, Tw.border_gray_200, Tw.rounded_lg ] ]
            [ div [ css [ Tw.text_center ] ]
                [ Icon.outline Template [ Tw.w_12, Tw.h_12, Tw.mx_auto, Color.text theme.color 500 ]
                , h2 [ css [ Tw.mt_2, Tw.text_lg, Tw.font_medium, Tw.text_gray_900 ] ]
                    [ text "Hello from Azimutt 👋" ]
                , p [ css [ Tw.mt_3, Tw.text_sm, Tw.text_gray_500 ] ]
                    [ text "Azimutt let you explore your database schema as freely as possible. To start, just type what you are looking for in the "
                    , button [ onClick (Focus Conf.ids.searchInput), css [ Tu.link, Css.focus [ Tw.outline_none ] ] ] [ text "search bar" ]
                    , text ", and then look at column and follow relations. Also, you can save your current layout for later."
                    ]
                , p [ css [ Tw.mt_3, Tw.text_sm, Tw.text_gray_500 ] ]
                    [ text "Your project has "
                    , bText (tables |> S.pluralizeD "table")
                    , text ". Here are some that could be interesting:"
                    , div [] (bestTables |> List.map (\t -> Badge.basic theme.color [ onClick (ShowTable t.id), css [ Tw.m_1, Tw.cursor_pointer ] ] [ text (TableId.show t.id) ]))
                    ]
                , p [ css [ Tw.mt_3, Tw.text_sm, Tw.text_gray_500 ] ]
                    [ text "If you like Azimutt, "
                    , sendTweet Conf.constants.cheeringTweet [ css [ Tu.link ] ] [ text "come and say hi" ]
                    , text ". We are eager to learn how you use it and for what. We also love "
                    , extLink Conf.constants.azimuttFeatureRequests [ css [ Tu.link ] ] [ text "feedback and feature requests" ]
                    , text "."
                    ]
                ]
            ]
        ]



-- HELPERS


buildRelationFull : Dict TableId Table -> Dict TableId TableFull -> Relation -> Maybe RelationFull
buildRelationFull allTables shownTables rel =
    Maybe.map2 (\src ref -> { name = rel.name, src = src, ref = ref, origins = rel.origins })
        (rel.src |> buildColumnRefFull allTables shownTables)
        (rel.ref |> buildColumnRefFull allTables shownTables)


buildColumnRefFull : Dict TableId Table -> Dict TableId TableFull -> ColumnRef -> Maybe ColumnRefFull
buildColumnRefFull allTables shownTables ref =
    (allTables |> Dict.get ref.table |> M.andThenZip (\table -> table.columns |> Ned.get ref.column))
        |> Maybe.map
            (\( table, column ) ->
                { ref = ref
                , table = table
                , column = column
                , props = (shownTables |> Dict.get ref.table) |> Maybe.map (\t -> ( t.props, t.index, t.props.size ))
                }
            )
