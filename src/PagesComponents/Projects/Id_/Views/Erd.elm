module PagesComponents.Projects.Id_.Views.Erd exposing (viewErd)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Conf
import Dict exposing (Dict)
import Html exposing (Html, button, div, h2, main_, p, text)
import Html.Attributes exposing (class, classList, id, style)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Html.Styled as Styled
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.Html exposing (bText, extLink, sendTweet)
import Libs.Html.Attributes exposing (classes)
import Libs.Html.Events exposing (onWheel, stopPointerDown)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.String as S
import Libs.Tailwind exposing (bg_400, border_400)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), Msg(..), VirtualRelation)
import PagesComponents.Projects.Id_.Models.DragState exposing (DragState)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Updates.Drag as Drag
import PagesComponents.Projects.Id_.Views.Erd.Relation exposing (viewEmptyRelation, viewRelation, viewVirtualRelation)
import PagesComponents.Projects.Id_.Views.Erd.Table as Table exposing (viewTable)
import Tailwind.Utilities as Tw


viewErd : ScreenProps -> Erd -> CursorMode -> Maybe Area -> Maybe VirtualRelation -> HtmlId -> Maybe DragState -> Html Msg
viewErd screen erd cursorMode selectionBox virtualRelation openedDropdown dragging =
    let
        canvas : CanvasProps
        canvas =
            dragging |> M.filter (\d -> d.id == Conf.ids.erd) |> M.mapOrElse (\d -> erd.canvas |> Drag.moveCanvas d) erd.canvas

        tableProps : Dict TableId ErdTableProps
        tableProps =
            dragging |> M.filter (\d -> d.id /= Conf.ids.erd) |> M.mapOrElse (\d -> erd.tableProps |> Drag.moveTables d canvas.zoom) erd.tableProps

        displayedTables : Dict TableId ErdTableProps
        displayedTables =
            tableProps |> Dict.filter (\_ t -> t.size /= Size.zero && (erd.shownTables |> List.member t.id))

        displayedRelations : List ErdRelation
        displayedRelations =
            erd.relations |> List.filter (\r -> [ r.src, r.ref ] |> List.any (\c -> displayedTables |> Dict.member c.table))

        virtualRelationInfo : Maybe ( ( Maybe ErdColumnProps, ErdColumn ), Position )
        virtualRelationInfo =
            virtualRelation
                |> Maybe.andThen
                    (\vr ->
                        vr.src
                            |> Maybe.andThen
                                (\src ->
                                    (erd |> Erd.getColumn src.table src.column)
                                        |> Maybe.map
                                            (\ref ->
                                                ( ( erd |> Erd.getColumnProps src.table src.column, ref )
                                                , vr.mouse |> CanvasProps.adapt screen canvas
                                                )
                                            )
                                )
                    )
    in
    main_
        [ class "tw-erd"
        , classList
            [ ( "tw-cursor-hand", cursorMode == CursorDrag && dragging == Nothing && virtualRelation == Nothing )
            , ( "tw-cursor-hand-drag", cursorMode == CursorDrag && dragging /= Nothing && virtualRelation == Nothing )
            , ( "tw-cursor-cross", virtualRelation /= Nothing )
            ]
        , id Conf.ids.erd
        , onWheel OnWheel
        , stopPointerDown (.position >> DragStart (B.cond (cursorMode == CursorDrag) Conf.ids.erd Conf.ids.selectionBox))
        ]
        [ div
            [ class "tw-canvas origin-top-left"
            , style "transform" ("translate(" ++ String.fromFloat canvas.position.left ++ "px, " ++ String.fromFloat canvas.position.top ++ "px) scale(" ++ String.fromFloat canvas.zoom ++ ")")
            ]
            [ viewTables cursorMode virtualRelation openedDropdown dragging canvas.zoom tableProps erd.tables erd.shownTables
            , Lazy.lazy2 viewRelations displayedTables displayedRelations
            , selectionBox |> M.filterNot (\_ -> tableProps |> Dict.isEmpty) |> M.mapOrElse viewSelectionBox (div [] [])
            , virtualRelationInfo |> M.mapOrElse viewVirtualRelation viewEmptyRelation
            ]
        , if tableProps |> Dict.isEmpty then
            viewEmptyState erd.tables

          else
            div [] []
        ]


viewTables : CursorMode -> Maybe VirtualRelation -> HtmlId -> Maybe DragState -> ZoomLevel -> Dict TableId ErdTableProps -> Dict TableId ErdTable -> List TableId -> Html Msg
viewTables cursorMode virtualRelation openedDropdown dragging zoom tableProps tables shownTables =
    Keyed.node "div"
        [ class "tw-tables" ]
        (shownTables
            |> List.reverse
            |> List.indexedMap (\index tableId -> ( index, tableId ))
            |> List.filterMap (\( index, tableId ) -> Maybe.map2 (\table props -> ( index, table, props )) (tables |> Dict.get tableId) (tableProps |> Dict.get tableId))
            |> List.map
                (\( index, table, props ) ->
                    ( TableId.toString table.id
                    , Lazy.lazy6 viewTable
                        zoom
                        cursorMode
                        (Table.argsToString
                            (B.cond (openedDropdown |> String.startsWith table.htmlId) openedDropdown "")
                            (dragging |> M.any (\d -> d.id == table.htmlId && d.init /= d.last))
                            (virtualRelation /= Nothing)
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
        [ classes [ "tw-selection-area absolute border-2 bg-opacity-25 z-max", border_400 Color.teal, bg_400 Color.teal ]
        , style "transform" ("translate(" ++ String.fromFloat area.position.left ++ "px, " ++ String.fromFloat area.position.top ++ "px)")
        , style "width" (String.fromFloat area.size.width ++ "px")
        , style "height" (String.fromFloat area.size.height ++ "px")
        ]
        []


viewEmptyState : Dict TableId ErdTable -> Html Msg
viewEmptyState tables =
    let
        bestTables : List ErdTable
        bestTables =
            tables
                |> Dict.values
                |> L.filterNot (\t -> (t.schema |> String.contains "_") || (t.name |> String.contains "_") || (t.schema |> String.contains "-") || (t.name |> String.contains "-"))
                |> List.sortBy (\t -> (t.name |> String.length) - (t.columns |> Ned.size))
                |> List.take 10
    in
    div [ class "flex h-full justify-center items-center" ]
        [ div [ class "max-w-prose p-6 bg-white border border-gray-200 rounded-lg" ]
            [ div [ class "text-center" ]
                [ Icon.outline Template [ Tw.w_12, Tw.h_12, Tw.mx_auto, Color.text Conf.theme.color 500 ] |> Styled.toUnstyled
                , h2 [ class "mt-2 text-lg font-medium text-gray-900" ]
                    [ text "Hello from Azimutt 👋" ]
                , p [ class "mt-3 text-sm text-gray-500" ]
                    [ text "Azimutt let you freely explore your database schema. To start, just type what you are looking for in the "
                    , button [ onClick (Focus Conf.ids.searchInput), class "tw-link focus:outline-none" ] [ text "search bar" ]
                    , text ", and then look at columns and follow relations. Once you have interesting layout, you can save it for later."
                    ]
                , p [ class "mt-3 text-sm text-gray-500" ]
                    [ text "Your project has "
                    , bText (tables |> S.pluralizeD "table")
                    , text ". Here are some that could be interesting:"
                    , div [] (bestTables |> List.map (\t -> Badge.basic Conf.theme.color [ onClick (ShowTable t.id), class "m-1 cursor-pointer" ] [ text (TableId.show t.id) ]))
                    ]
                , p [ class "mt-3 text-sm text-gray-500" ]
                    [ text "If you ♥️ Azimutt, "
                    , sendTweet Conf.constants.cheeringTweet [ class "tw-link" ] [ text "come and say hi" ]
                    , text ". We are eager to learn how you use it and for what. We also love "
                    , extLink Conf.constants.azimuttFeatureRequests [ class "tw-link" ] [ text "feedback and feature requests" ]
                    , text "."
                    ]
                ]
            ]
        ]
