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
import Html.Styled.Lazy as Lazy
import Libs.Area exposing (Area)
import Libs.Bool as B
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
import Models.Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), DragState, Msg(..), VirtualRelation)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd, ErdColumn, ErdColumnProps, ErdColumnRef, ErdRelation, ErdTable, ErdTableProps)
import PagesComponents.Projects.Id_.Updates.Drag as Drag
import PagesComponents.Projects.Id_.Views.Erd.Relation exposing (viewEmptyRelation, viewRelation, viewVirtualRelation)
import PagesComponents.Projects.Id_.Views.Erd.Table as Table exposing (viewTable)
import Tailwind.Utilities as Tw


type alias Model x =
    { x
        | screen : ScreenProps
        , cursorMode : CursorMode
        , selectionBox : Maybe Area
        , virtualRelation : Maybe VirtualRelation
        , openedDropdown : HtmlId
        , dragging : Maybe DragState
        , hoverTable : Maybe TableId
        , hoverColumn : Maybe ColumnRef
    }


viewErd : Theme -> Model x -> Project -> Erd -> Html Msg
viewErd theme model project erd =
    let
        canvas : CanvasProps
        canvas =
            model.dragging |> M.filter (\d -> d.id == Conf.ids.erd) |> M.mapOrElse (\d -> project.layout.canvas |> Drag.moveCanvas d) project.layout.canvas

        tableProps : Dict TableId ErdTableProps
        tableProps =
            model.dragging |> M.filter (\d -> d.id /= Conf.ids.erd) |> M.mapOrElse (\d -> erd.tableProps |> Drag.moveTables2 d canvas.zoom) erd.tableProps

        displayedTables : Dict TableId ErdTableProps
        displayedTables =
            tableProps |> Dict.filter (\_ t -> t.size /= Size.zero && (erd.shownTables |> List.member t.id))

        displayedRelations : List ErdRelation
        displayedRelations =
            erd.relations |> List.filter (\r -> [ r.src, r.ref ] |> List.any (\c -> displayedTables |> Dict.member c.table))

        virtualRelation : Maybe ( ( Maybe ErdColumnProps, ErdColumn ), Position )
        virtualRelation =
            model.virtualRelation
                |> Maybe.andThen
                    (\vr ->
                        vr.src
                            |> Maybe.andThen
                                (\src ->
                                    (erd |> Erd.getColumn src.table src.column)
                                        |> Maybe.map
                                            (\ref ->
                                                ( ( erd |> Erd.getColumnProps src.table src.column, ref )
                                                , vr.mouse |> CanvasProps.adapt model.screen canvas
                                                )
                                            )
                                )
                    )
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
        [ div [ class "tw-canvas", css [ Tw.transform, Tw.origin_top_left, Tu.translate_x_y canvas.position.left canvas.position.top "px", Tu.scale canvas.zoom ] ]
            [ Lazy.lazy5 viewTables model canvas.zoom tableProps erd.tables erd.shownTables
            , Lazy.lazy2 viewRelations displayedTables displayedRelations
            , model.selectionBox |> M.filterNot (\_ -> tableProps |> Dict.isEmpty) |> M.mapOrElse viewSelectionBox (div [] [])
            , virtualRelation |> M.mapOrElse viewVirtualRelation viewEmptyRelation
            ]
        , if tableProps |> Dict.isEmpty then
            viewEmptyState theme project.tables

          else
            div [] []
        ]


viewTables : Model x -> ZoomLevel -> Dict TableId ErdTableProps -> Dict TableId ErdTable -> List TableId -> Html Msg
viewTables model zoom tableProps tables shownTables =
    Keyed.node "div"
        [ class "tw-tables" ]
        (shownTables
            |> List.indexedMap (\index tableId -> ( index, tableId ))
            |> List.filterMap (\( index, tableId ) -> Maybe.map2 (\table props -> ( index, table, props )) (tables |> Dict.get tableId) (tableProps |> Dict.get tableId))
            |> List.map
                (\( index, table, props ) ->
                    ( TableId.toString table.id
                    , Lazy.lazy6 viewTable
                        zoom
                        model.cursorMode
                        (Table.argsToString
                            (B.cond (model.openedDropdown |> String.startsWith table.htmlId) model.openedDropdown "")
                            (model.dragging |> M.any (\d -> d.id == table.htmlId && d.init /= d.last))
                            (model.virtualRelation /= Nothing)
                        )
                        index
                        props
                        table
                    )
                )
        )


viewRelations : Dict TableId ErdTableProps -> List ErdRelation -> Html Msg
viewRelations tableProps relations =
    let
        getColumnProps : ErdColumnRef -> Maybe ErdColumnProps
        getColumnProps ref =
            tableProps |> Dict.get ref.table |> Maybe.andThen (\t -> t.columnProps |> Dict.get ref.column)
    in
    Keyed.node "div"
        [ class "tw-relations" ]
        (relations |> List.map (\r -> ( r.name, Lazy.lazy3 viewRelation (getColumnProps r.src) (getColumnProps r.ref) r )))


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
            , Tw.absolute
            , Tu.z_max
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
