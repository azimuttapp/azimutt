module PagesComponents.Projects.Id_.Views.Erd exposing (ErdArgs, argsToString, stringToArgs, viewErd)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict exposing (Dict)
import Html exposing (Html, button, div, h2, p, text)
import Html.Attributes exposing (class, classList, id, style)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html exposing (bText, extLink, sendTweet)
import Libs.Html.Attributes as Attributes exposing (css)
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onWheel, stopPointerDown)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.String as String
import Libs.Tailwind as Tw exposing (focus)
import Libs.Tuple as Tuple
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import Models.RelationStyle exposing (RelationStyle)
import Models.Size as Size
import PagesComponents.Projects.Id_.Models exposing (Msg(..), VirtualRelation)
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Projects.Id_.Models.DragState exposing (DragState)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Projects.Id_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Projects.Id_.Models.ErdTableNotes as ErdTableNotes exposing (ErdTableNotes)
import PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Updates.Drag as Drag
import PagesComponents.Projects.Id_.Views.Erd.Relation as Relation exposing (viewEmptyRelation, viewRelation, viewVirtualRelation)
import PagesComponents.Projects.Id_.Views.Erd.Table as Table exposing (viewTable)
import PagesComponents.Projects.Id_.Views.Modals.ErdContextMenu as ErdContextMenu
import Set


type alias ErdArgs =
    String


argsToString : Platform -> CursorMode -> String -> String -> ErdArgs
argsToString platform cursorMode openedDropdown openedPopover =
    [ Platform.toString platform, CursorMode.toString cursorMode, openedDropdown, openedPopover ] |> String.join "~"


stringToArgs : ErdArgs -> ( ( Platform, CursorMode ), ( String, String ) )
stringToArgs args =
    case args |> String.split "~" of
        [ platform, cursorMode, openedDropdown, openedPopover ] ->
            ( ( Platform.fromString platform, CursorMode.fromString cursorMode ), ( openedDropdown, openedPopover ) )

        _ ->
            ( ( Platform.PC, CursorMode.Select ), ( "", "" ) )


viewErd : ErdConf -> ErdProps -> Maybe TableId -> Erd -> Maybe Area.Canvas -> Maybe VirtualRelation -> ErdArgs -> Maybe DragState -> Html Msg
viewErd conf erdElem hoverTable erd selectionBox virtualRelation args dragging =
    let
        ( ( platform, cursorMode ), ( openedDropdown, openedPopover ) ) =
            stringToArgs args

        layout : ErdLayout
        layout =
            erd |> Erd.currentLayout

        canvas : CanvasProps
        canvas =
            dragging |> Maybe.filter (\d -> d.id == Conf.ids.erd) |> Maybe.mapOrElse (\d -> layout.canvas |> Drag.moveCanvas d) layout.canvas

        -- TODO: use to render only visible tables => needs to handle size change to 0...
        --canvasViewport : Area.Canvas
        --canvasViewport =
        --    canvas |> CanvasProps.viewport erdElem
        tableProps : List ErdTableLayout
        tableProps =
            dragging |> Maybe.filter (\d -> d.id /= Conf.ids.erd) |> Maybe.mapOrElse (\d -> layout.tables |> Drag.moveTables d canvas.zoom) layout.tables

        displayedTables : List ErdTableLayout
        displayedTables =
            tableProps |> List.filter (\t -> t.props.size /= Size.zeroCanvas)

        displayedIds : Set.Set TableId
        displayedIds =
            displayedTables |> List.map .id |> Set.fromList

        displayedRelations : List ErdRelation
        displayedRelations =
            erd.relations |> List.filter (\r -> [ r.src, r.ref ] |> List.any (\c -> displayedIds |> Set.member c.table))

        virtualRelationInfo : Maybe ( ( Maybe { table : ErdTableProps, column : ErdColumnProps, index : Int }, ErdColumn ), Position.Canvas )
        virtualRelationInfo =
            virtualRelation
                |> Maybe.andThen
                    (\vr ->
                        vr.src
                            |> Maybe.andThen
                                (\src ->
                                    (erd |> Erd.getColumn src)
                                        |> Maybe.map
                                            (\ref ->
                                                ( ( Relation.buildColumnInfo src.column (tableProps |> List.findBy .id src.table), ref )
                                                , vr.mouse |> Erd.viewportToCanvas erdElem canvas
                                                )
                                            )
                                )
                    )
    in
    div
        [ class "az-erd h-full bg-gray-100 overflow-hidden"
        , classList
            [ ( "cursor-grab-all", cursorMode == CursorMode.Drag && dragging == Nothing && virtualRelation == Nothing )
            , ( "cursor-grabbing-all", cursorMode == CursorMode.Drag && dragging /= Nothing && virtualRelation == Nothing )
            , ( "cursor-crosshair-all", virtualRelation /= Nothing )
            ]
        , id Conf.ids.erd
        , Attributes.when (conf.move && not (List.isEmpty tableProps)) (onWheel platform OnWheel)
        , Attributes.when (conf.move || conf.select) (stopPointerDown platform (handleErdPointerDown conf cursorMode))
        , Attributes.when conf.layout (onContextMenu platform (ContextMenuCreate (ErdContextMenu.view platform)))
        ]
        [ div [ class "az-canvas origin-top-left", Position.styleTransformDiagram canvas.position canvas.zoom ]
            -- use HTML order instead of z-index, must be careful with it, this allows to have tooltips & popovers always on top
            [ displayedRelations |> Lazy.lazy5 viewRelations conf erd.settings.defaultSchema erd.settings.relationStyle displayedTables
            , tableProps |> viewTables platform conf cursorMode virtualRelation openedDropdown openedPopover hoverTable dragging canvas.zoom erd.settings.defaultSchema erd.settings.columnBasicTypes erd.tables erd.notes
            , selectionBox |> Maybe.filterNot (\_ -> tableProps |> List.isEmpty) |> Maybe.mapOrElse viewSelectionBox (div [] [])
            , virtualRelationInfo |> Maybe.mapOrElse (viewVirtualRelation erd.settings.relationStyle) viewEmptyRelation
            ]
        , if tableProps |> List.isEmpty then
            viewEmptyState erd.settings.defaultSchema erd.tables

          else
            div [] []
        ]


handleErdPointerDown : ErdConf -> CursorMode -> PointerEvent -> Msg
handleErdPointerDown conf cursorMode e =
    if e.button == MainButton then
        case cursorMode of
            CursorMode.Drag ->
                if conf.move then
                    e |> .clientPos |> DragStart Conf.ids.erd

                else
                    Noop "No erd drag"

            CursorMode.Select ->
                if conf.select then
                    e |> .clientPos |> DragStart Conf.ids.selectionBox

                else
                    Noop "No selection box"

    else if e.button == MiddleButton then
        if conf.move then
            e |> .clientPos |> DragStart Conf.ids.erd

        else
            Noop "No middle button erd drag"

    else
        Noop "No match on erd pointer down"


viewTables : Platform -> ErdConf -> CursorMode -> Maybe VirtualRelation -> HtmlId -> HtmlId -> Maybe TableId -> Maybe DragState -> ZoomLevel -> SchemaName -> Bool -> Dict TableId ErdTable -> Dict TableId ErdTableNotes -> List ErdTableLayout -> Html Msg
viewTables platform conf cursorMode virtualRelation openedDropdown openedPopover hoverTable dragging zoom defaultSchema useBasicTypes tables notes tableLayouts =
    Keyed.node "div"
        [ class "az-tables" ]
        (tableLayouts
            |> List.reverse
            |> List.indexedMap Tuple.new
            |> List.filterMap (\( index, tableLayout ) -> tables |> Dict.get tableLayout.id |> Maybe.map (\table -> ( index, table, tableLayout )))
            |> List.map
                (\( index, table, tableLayout ) ->
                    ( TableId.toString table.id
                    , Lazy.lazy6 viewTable
                        conf
                        zoom
                        (Table.argsToString
                            platform
                            cursorMode
                            defaultSchema
                            (B.cond (openedDropdown |> String.startsWith table.htmlId) openedDropdown "")
                            (B.cond (openedPopover |> String.startsWith table.htmlId) openedPopover "")
                            index
                            (hoverTable == Just table.id)
                            (dragging |> Maybe.any (\d -> d.id == table.htmlId && d.init /= d.last))
                            (virtualRelation /= Nothing)
                            useBasicTypes
                        )
                        (notes |> Dict.getOrElse table.id ErdTableNotes.empty)
                        tableLayout
                        table
                    )
                )
        )


viewRelations : ErdConf -> SchemaName -> RelationStyle -> List ErdTableLayout -> List ErdRelation -> Html Msg
viewRelations conf defaultSchema style tableLayouts relations =
    Keyed.node "div"
        [ class "az-relations" ]
        (relations
            |> List.map
                (\r ->
                    ( r.name
                    , Lazy.lazy6 viewRelation
                        defaultSchema
                        style
                        conf
                        (tableLayouts |> List.findBy .id r.src.table)
                        (tableLayouts |> List.findBy .id r.ref.table)
                        r
                    )
                )
        )


viewSelectionBox : Area.Canvas -> Html Msg
viewSelectionBox area =
    div ([ css [ "az-selection-area absolute border-2 bg-opacity-25 z-max border-teal-400 bg-teal-400" ] ] ++ Area.styleTransformCanvas area) []


viewEmptyState : SchemaName -> Dict TableId ErdTable -> Html Msg
viewEmptyState defaultSchema tables =
    let
        bestOneWordTables : List ErdTable
        bestOneWordTables =
            tables
                |> Dict.values
                |> List.filterNot (\t -> (t.schema |> String.contains "_") || (t.name |> String.contains "_") || (t.schema |> String.contains "-") || (t.name |> String.contains "-"))
                |> List.sortBy (\t -> (t.name |> String.length) - (t.columns |> Dict.size))
                |> List.take 10

        bestTables : List ErdTable
        bestTables =
            if bestOneWordTables |> List.isEmpty then
                tables
                    |> Dict.values
                    |> List.sortBy (\t -> (t.name |> String.length) - (t.columns |> Dict.size))
                    |> List.take 10

            else
                bestOneWordTables
    in
    div [ class "flex h-full justify-center items-center" ]
        [ div [ class "max-w-prose p-6 bg-white border border-gray-200 rounded-lg" ]
            [ div [ class "text-center" ]
                [ Icon.outline2x Template "mx-auto text-primary-500"
                , h2 [ class "mt-2 text-lg font-medium text-gray-900" ]
                    [ text "Hello from Azimutt 👋" ]
                , if tables |> Dict.isEmpty then
                    p [ class "mt-3 text-sm text-gray-500" ]
                        [ text "Azimutt allows you to create and explore your database schema. Start writing your schema using "
                        , extLink "https://github.com/azimuttapp/azimutt/blob/main/docs/aml/README.md" [ class "link" ] [ text "AML syntax" ]
                        , text " or import and explore your schema. Add any source (database url, SQL or JSON) in project settings (top right "
                        , Icon.outline Icon.Cog "h-5 w-5 inline"
                        , text ")."
                        ]

                  else
                    div []
                        [ p [ class "mt-3 text-sm text-gray-500" ]
                            [ text "Azimutt allows you to explore your database schema. Start by typing what you are looking for in the "
                            , button [ onClick (Focus Conf.ids.searchInput), css [ "link", focus [ "outline-none" ] ] ] [ text "search bar" ]
                            , text ", and then look at columns, follow relations and more... Create new layouts to save them for later."
                            ]
                        , p [ class "mt-3 text-sm text-gray-500" ]
                            [ text "Your project has "
                            , bText (tables |> String.pluralizeD "table")
                            , text ". Here are some that could be interesting:"
                            , div [] (bestTables |> List.map (\t -> Badge.basic Tw.primary [ onClick (ShowTable t.id Nothing), class "m-1 cursor-pointer" ] [ text (TableId.show defaultSchema t.id) ] |> Tooltip.t (t.columns |> String.pluralizeD "column")))
                            ]
                        ]
                , p [ class "mt-3 text-sm text-gray-500" ]
                    [ text "If you ❤️ Azimutt, "
                    , sendTweet Conf.constants.cheeringTweet [ class "link" ] [ text "come and say hi" ]
                    , text ". We are eager to learn how you use it and for what. We also love "
                    , extLink Conf.constants.azimuttFeatureRequests [ class "link" ] [ text "feedback and feature requests" ]
                    , text "."
                    ]
                ]
            ]
        ]
