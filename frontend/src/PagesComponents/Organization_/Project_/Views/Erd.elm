module PagesComponents.Organization_.Project_.Views.Erd exposing (ErdArgs, argsToString, stringToArgs, viewErd)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict exposing (Dict)
import Html exposing (Html, button, div, h2, input, p, text)
import Html.Attributes exposing (autofocus, class, classList, id, name, placeholder, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html exposing (bText, extLink, sendTweet)
import Libs.Html.Attributes exposing (css)
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onDblClick, onPointerDown, onWheel)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.String as String
import Libs.Tailwind as Tw exposing (focus)
import Libs.Time as Time
import Libs.Tuple as Tuple
import Models.Area as Area
import Models.DbSource as DbSource
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Group as Group exposing (Group)
import Models.Project.Metadata exposing (Metadata)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableMeta as TableMeta exposing (TableMeta)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.RelationStyle exposing (RelationStyle)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (GroupEdit, GroupMsg(..), MemoEdit, MemoMsg(..), Msg(..), VirtualRelation)
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.DragState exposing (DragState)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId
import PagesComponents.Organization_.Project_.Updates.Drag as Drag
import PagesComponents.Organization_.Project_.Views.Erd.Memo as Memo
import PagesComponents.Organization_.Project_.Views.Erd.Relation as Relation exposing (viewEmptyRelation, viewRelation, viewVirtualRelation)
import PagesComponents.Organization_.Project_.Views.Erd.Table as Table exposing (viewTable)
import PagesComponents.Organization_.Project_.Views.Erd.TableRow as TableRow exposing (viewTableRow)
import PagesComponents.Organization_.Project_.Views.Modals.ErdContextMenu as ErdContextMenu
import PagesComponents.Organization_.Project_.Views.Modals.GroupContextMenu as GroupContextMenu
import Set exposing (Set)
import Time


type alias ErdArgs =
    String


argsToString : Platform -> CursorMode -> Maybe TableId -> String -> String -> DetailsSidebar.Selected -> Maybe GroupEdit -> Time.Posix -> ErdArgs
argsToString platform cursorMode hoverTable openedDropdown openedPopover selected editGroup now =
    [ Platform.toString platform, CursorMode.toString cursorMode, hoverTable |> Maybe.mapOrElse TableId.toString "", openedDropdown, openedPopover, selected, editGroup |> Maybe.mapOrElse (.index >> String.fromInt) "", editGroup |> Maybe.mapOrElse .content "", Time.posixToMillis now |> String.fromInt ] |> String.join "~"


stringToArgs : ErdArgs -> ( ( Platform, CursorMode, Maybe TableId ), ( String, String, DetailsSidebar.Selected ), ( Maybe GroupEdit, Time.Posix ) )
stringToArgs args =
    case args |> String.split "~" of
        [ platform, cursorMode, hoverTable, openedDropdown, openedPopover, selected, editGroupIndex, editGroupContent, now ] ->
            ( ( Platform.fromString platform, CursorMode.fromString cursorMode, hoverTable |> TableId.fromString ), ( openedDropdown, openedPopover, selected ), ( editGroupIndex |> String.toInt |> Maybe.map (\index -> { index = index, content = editGroupContent }), now |> String.toInt |> Maybe.withDefault 0 |> Time.millisToPosix ) )

        _ ->
            ( ( Platform.PC, CursorMode.Select, Nothing ), ( "", "", "" ), ( Nothing, Time.zero ) )


viewErd : ErdConf -> ErdProps -> Erd -> Maybe Area.Canvas -> Maybe VirtualRelation -> Maybe MemoEdit -> ErdArgs -> Maybe DragState -> Html Msg
viewErd conf erdElem erd selectionBox virtualRelation editMemo args dragging =
    let
        ( ( platform, cursorMode, hoverTable ), ( openedDropdown, openedPopover, selected ), ( editGroup, now ) ) =
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
        draggedLayout : ErdLayout
        draggedLayout =
            dragging |> Maybe.mapOrElse (\d -> layout |> Drag.moveInLayout d canvas.zoom) layout

        layoutTables : List ErdTableLayout
        layoutTables =
            draggedLayout.tables

        tableRows : List TableRow
        tableRows =
            draggedLayout.tableRows

        memos : List Memo
        memos =
            draggedLayout.memos

        displayedTables : List ErdTableLayout
        displayedTables =
            layoutTables |> List.filter (\t -> t.props.size /= Size.zeroCanvas)

        groups : List ( Int, Group, Area.Canvas )
        groups =
            layout.groups |> List.zipWithIndex |> List.filterMap (ErdTableLayout.buildGroupArea displayedTables)

        displayedIds : Set TableId
        displayedIds =
            displayedTables |> List.map .id |> Set.fromList

        displayedRelations : List ErdRelation
        displayedRelations =
            erd.relations |> List.filter (\r -> [ r.src, r.ref ] |> List.any (\c -> displayedIds |> Set.member c.table))

        virtualRelationInfo : Maybe ( ( Maybe { table : ErdTableProps, index : Int, highlighted : Bool }, ErdColumn ), Position.Canvas )
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
                                                ( ( Relation.buildColumnInfo src.column (layoutTables |> List.findBy .id src.table), ref )
                                                , vr.mouse |> Erd.viewportToCanvas erdElem canvas
                                                )
                                            )
                                )
                    )
    in
    div
        ([ id Conf.ids.erd
         , class "az-erd h-full bg-gray-100 overflow-hidden"
         , classList
            [ ( "invisible", List.nonEmpty layoutTables && (erdElem.size == Size.zeroViewport || erd.layoutOnLoad /= "") )
            , ( "cursor-grab-all", cursorMode == CursorMode.Drag && dragging == Nothing && virtualRelation == Nothing )
            , ( "cursor-grabbing-all", cursorMode == CursorMode.Drag && dragging /= Nothing && virtualRelation == Nothing )
            , ( "cursor-crosshair-all", virtualRelation /= Nothing )
            ]
         ]
            ++ B.cond (conf.move && ErdLayout.nonEmpty layout) [ onWheel OnWheel platform ] []
            ++ B.cond ((conf.move || conf.select) && virtualRelation == Nothing && editMemo == Nothing) [ onPointerDown (handleErdPointerDown conf cursorMode) platform ] []
            ++ B.cond (conf.layout && virtualRelation == Nothing && editMemo == Nothing && ErdLayout.nonEmpty layout) [ onDblClick (CanvasProps.eventCanvas erdElem canvas >> MCreate >> MemoMsg) platform, onContextMenu (\e -> ContextMenuCreate (ErdContextMenu.view platform erdElem canvas layout e) e) platform ] []
        )
        [ div [ class "az-canvas origin-top-left", Position.styleTransformDiagram canvas.position canvas.zoom ]
            -- use HTML order instead of z-index, must be careful with it, this allows to have tooltips & popovers always on top
            [ -- canvas.position |> Position.debugDiagram "canvas" "bg-black"
              -- , layout.tables |> List.map (.props >> Area.offGrid) |> Area.mergeCanvas |> Maybe.mapOrElse (Area.debugCanvas "tablesArea" "border-blue-500") (div [] []),
              div [ class "az-groups" ] (groups |> List.map (viewGroup platform erd.settings.defaultSchema editGroup))
            , tableRows |> viewTableRows now platform conf cursorMode erd.settings.defaultSchema openedDropdown erd.sources layout erd.metadata
            , displayedRelations |> Lazy.lazy5 viewRelations conf erd.settings.defaultSchema erd.settings.relationStyle displayedTables
            , layoutTables |> viewTables platform conf cursorMode virtualRelation openedDropdown openedPopover hoverTable dragging canvas.zoom erd.settings.defaultSchema selected erd.settings.columnBasicTypes erd.tables erd.metadata layout
            , memos |> viewMemos platform conf cursorMode editMemo
            , div [ class "az-selection-box pointer-events-none" ] (selectionBox |> Maybe.filter (\_ -> layout |> ErdLayout.nonEmpty) |> Maybe.mapOrElse viewSelectionBox [])
            , div [ class "az-virtual-relation pointer-events-none" ] [ virtualRelationInfo |> Maybe.mapOrElse (\i -> viewVirtualRelation erd.settings.relationStyle i) viewEmptyRelation ]
            ]
        , if layout |> ErdLayout.isEmpty then
            viewEmptyState erd.settings.defaultSchema erd.tables

          else
            div [] []
        ]


viewMemos : Platform -> ErdConf -> CursorMode -> Maybe MemoEdit -> List Memo -> Html Msg
viewMemos platform conf cursorMode editMemo memos =
    Keyed.node "div"
        [ class "az-memos" ]
        (memos
            |> List.map
                (\memo ->
                    ( MemoId.toHtmlId memo.id
                    , Lazy.lazy5 Memo.viewMemo platform conf cursorMode (editMemo |> Maybe.filterBy .id memo.id |> Maybe.map .content) memo
                    )
                )
        )


viewTableRows : Time.Posix -> Platform -> ErdConf -> CursorMode -> SchemaName -> HtmlId -> List Source -> ErdLayout -> Metadata -> List TableRow -> Html Msg
viewTableRows now platform conf cursorMode defaultSchema openedDropdown sources layout metadata tableRows =
    Keyed.node "div"
        [ class "az-table-rows" ]
        (tableRows
            -- last one added on top
            |> List.reverse
            |> List.map
                (\r ->
                    ( TableRow.toHtmlId r.id
                    , viewTableRow now
                        platform
                        conf
                        cursorMode
                        defaultSchema
                        openedDropdown
                        (TableRow.toHtmlId r.id)
                        (sources |> List.findBy .id r.source |> Maybe.andThen DbSource.fromSource)
                        (layout.tables |> List.findBy .id r.query.table)
                        (metadata |> Dict.get r.query.table)
                        r
                    )
                )
        )


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


viewGroup : Platform -> SchemaName -> Maybe GroupEdit -> ( Int, Group, Area.Canvas ) -> Html Msg
viewGroup platform defaultSchema editGroup ( index, group, area ) =
    div
        ([ css [ "absolute border-2 bg-opacity-25", Tw.bg_300 group.color, Tw.border_300 group.color ]
         , onDblClick (\_ -> GEdit index group.name |> GroupMsg) platform
         , onContextMenu (\e -> ContextMenuCreate (GroupContextMenu.view defaultSchema index group) e) platform
         ]
            ++ Area.styleTransformCanvas area
        )
        [ editGroup
            |> Maybe.filter (\edit -> edit.index == index)
            |> Maybe.mapOrElse
                (\edit ->
                    let
                        inputId : HtmlId
                        inputId =
                            Group.toInputId index
                    in
                    input
                        [ type_ "text"
                        , name inputId
                        , id inputId
                        , placeholder "Group name"
                        , value edit.content
                        , onInput (GEditUpdate >> GroupMsg)
                        , onBlur (GEditSave |> GroupMsg)
                        , autofocus True
                        , css [ "px-2 py-0 shadow-sm block border-gray-300 rounded-md", focus [ Tw.ring_500 group.color, Tw.border_500 group.color ] ]
                        ]
                        []
                )
                (div [ css [ "px-2 select-none", Tw.text_600 group.color ] ] [ text group.name ])
        ]


viewTables : Platform -> ErdConf -> CursorMode -> Maybe VirtualRelation -> HtmlId -> HtmlId -> Maybe TableId -> Maybe DragState -> ZoomLevel -> SchemaName -> DetailsSidebar.Selected -> Bool -> Dict TableId ErdTable -> Metadata -> ErdLayout -> List ErdTableLayout -> Html Msg
viewTables platform conf cursorMode virtualRelation openedDropdown openedPopover hoverTable dragging zoom defaultSchema selected useBasicTypes tables metadata layout tableLayouts =
    Keyed.node "div"
        [ class "az-tables" ]
        (tableLayouts
            |> List.reverse
            |> List.indexedMap Tuple.new
            |> List.filterMap (\( index, tableLayout ) -> tables |> Dict.get tableLayout.id |> Maybe.map (\table -> ( index, table, tableLayout )))
            |> List.map
                (\( index, table, tableLayout ) ->
                    ( TableId.toString table.id
                    , Lazy.lazy7 viewTable
                        conf
                        zoom
                        (Table.argsToString
                            platform
                            cursorMode
                            defaultSchema
                            (B.cond (openedDropdown |> String.startsWith table.htmlId) openedDropdown "")
                            (B.cond (openedPopover |> String.startsWith table.htmlId) openedPopover "")
                            index
                            selected
                            (hoverTable == Just table.id)
                            (dragging |> Maybe.any (\d -> d.id == table.htmlId && d.init /= d.last))
                            (virtualRelation /= Nothing)
                            useBasicTypes
                        )
                        layout
                        (metadata |> Dict.getOrElse table.id TableMeta.empty)
                        tableLayout
                        table
                    )
                )
        )


viewRelations : ErdConf -> SchemaName -> RelationStyle -> List ErdTableLayout -> List ErdRelation -> Html Msg
viewRelations conf defaultSchema style tableLayouts relations =
    Keyed.node "div"
        [ class "az-relations select-none pointer-events-none" ]
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


viewSelectionBox : Area.Canvas -> List (Html Msg)
viewSelectionBox area =
    [ div ([ css [ "absolute border-2 bg-opacity-25 z-max border-teal-400 bg-teal-400" ] ] ++ Area.styleTransformCanvas area) [] ]


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
                            , div [] (bestTables |> List.map (\t -> Badge.roundedFlex Tw.primary [ onClick (ShowTable t.id Nothing), class "m-1 cursor-pointer" ] [ text (TableId.show defaultSchema t.id) ] |> Tooltip.t (t.columns |> String.pluralizeD "column")))
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
