module Components.Organisms.Table exposing (Actions, CheckConstraint, Column, ColumnName, ColumnRef, DocState, IndexConstraint, Model, OrganizationId, ProjectId, ProjectInfo, Relation, SchemaName, SharedDocState, State, TableConf, TableName, TableRef, UniqueConstraint, doc, initDocState, table)

import Components.Atoms.Icon as Icon
import Components.Atoms.Icons as Icons
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..), ItemAction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Popover as Popover
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Attribute, Html, br, button, div, span, text)
import Html.Attributes exposing (class, classList, id, tabindex, title, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as Bool
import Libs.Html as Html exposing (bText)
import Libs.Html.Attributes as Attributes exposing (ariaExpanded, ariaHaspopup, css, role, track)
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onPointerUp, stopDoubleClick)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.Uuid exposing (Uuid)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Nel as Nel
import Libs.String as String
import Libs.Tailwind as Tw exposing (Color, TwClass, batch, bg_50, border_500, focus, ring_500, text_500)
import Set exposing (Set)
import Track


type alias Model msg =
    { id : HtmlId
    , ref : TableRef
    , label : String
    , isView : Bool
    , comment : Maybe String
    , notes : Maybe String
    , columns : List Column
    , hiddenColumns : List Column
    , dropdown : Maybe (Html msg)
    , state : State
    , actions : Actions msg
    , zoom : ZoomLevel
    , conf : TableConf
    , project : ProjectInfo
    , platform : Platform
    , defaultSchema : SchemaName
    }


type alias TableRef =
    { schema : String, table : String }


type alias Column =
    { index : Int
    , name : ColumnName
    , kind : String
    , kindDetails : Maybe String
    , nullable : Bool
    , default : Maybe String
    , comment : Maybe String
    , notes : Maybe String
    , isPrimaryKey : Bool
    , inRelations : List Relation
    , outRelations : List Relation
    , uniques : List UniqueConstraint
    , indexes : List IndexConstraint
    , checks : List CheckConstraint
    }


type alias State =
    { color : Color
    , isHover : Bool
    , highlightedColumns : Set String
    , selected : Bool
    , collapsed : Bool
    , dragging : Bool
    , openedDropdown : HtmlId
    , openedPopover : HtmlId
    , showHiddenColumns : Bool
    }


type alias Actions msg =
    { hover : Bool -> msg
    , headerClick : PointerEvent -> msg
    , headerDblClick : msg
    , headerRightClick : PointerEvent -> msg
    , headerDropdownClick : HtmlId -> msg
    , columnHover : ColumnName -> Bool -> msg
    , columnClick : Maybe (ColumnName -> PointerEvent -> msg)
    , columnDblClick : ColumnName -> msg
    , columnRightClick : Int -> ColumnName -> PointerEvent -> msg
    , notesClick : Maybe ColumnName -> msg
    , relationsIconClick : List Relation -> Bool -> msg
    , hiddenColumnsHover : HtmlId -> Bool -> msg
    , hiddenColumnsClick : msg
    }


type alias TableConf =
    { layout : Bool, move : Bool, select : Bool, hover : Bool }


type alias Relation =
    { column : ColumnRef, nullable : Bool, tableShown : Bool }


type alias ColumnRef =
    { schema : String, table : String, column : String }


type alias UniqueConstraint =
    { name : String }


type alias IndexConstraint =
    { name : String }


type alias CheckConstraint =
    { name : String }


type alias SchemaName =
    String


type alias TableName =
    String


type alias ColumnName =
    String


type alias OrganizationId =
    Uuid


type alias ProjectId =
    Uuid


type alias ProjectInfo =
    { organization : Maybe { id : OrganizationId }, id : ProjectId }


table : Model msg -> Html msg
table model =
    div
        [ id model.id
        , Attributes.when model.conf.hover (onMouseEnter (model.actions.hover True))
        , Attributes.when model.conf.hover (onMouseLeave (model.actions.hover False))
        , css
            [ "inline-block bg-white rounded-lg"
            , Bool.cond model.state.isHover "shadow-lg" "shadow-md"
            , Bool.cond model.state.selected ("ring-4 " ++ ring_500 model.state.color) ""
            , Bool.cond model.state.dragging "cursor-move" ""
            ]
        ]
        [ Lazy.lazy viewHeader model
        , if model.state.collapsed then
            div [] []

          else
            div []
                [ Lazy.lazy viewColumns model
                , Lazy.lazy viewHiddenColumns model
                ]
        ]


viewHeader : Model msg -> Html msg
viewHeader model =
    let
        dropdownId : HtmlId
        dropdownId =
            model.id ++ "-dropdown"

        headerTextSize : List (Attribute msg)
        headerTextSize =
            if model.zoom < 0.5 then
                -- EXPERIMENT: disable table title magnification when small so the diagram doesn't change and makes the fit-to-screen flaky
                -- [ style "font-size" (String.fromFloat (1.25 * 0.5 / model.zoom) ++ "rem") ]
                []

            else
                []
    in
    div
        [ title model.label
        , css
            [ "flex items-center justify-items-center px-3 py-1 border-t-8 border-b border-b-default-200"
            , if model.state.collapsed || (List.isEmpty model.columns && List.isEmpty model.hiddenColumns) then
                "rounded-lg"

              else
                "rounded-t-lg"
            , border_500 model.state.color
            , bg_50 (Bool.cond model.state.isHover model.state.color Tw.default)
            ]
        ]
        [ div
            [ Attributes.when model.conf.select (onPointerUp model.platform model.actions.headerClick)
            , Attributes.when model.conf.layout (stopDoubleClick model.actions.headerDblClick)
            , Attributes.when model.conf.layout (onContextMenu model.platform model.actions.headerRightClick)
            , class "flex-grow text-center whitespace-nowrap"
            ]
            ([ if model.isView then
                span ([ class "text-xl italic underline decoration-dotted" ] ++ headerTextSize) [ text model.label ] |> Tooltip.t "This is a view"

               else
                span ([ class "text-xl" ] ++ headerTextSize) [ text model.label ]
             ]
                |> List.appendOn model.comment viewComment
                |> List.appendOn model.notes (viewNotes model Nothing)
            )
        , model.dropdown
            |> Maybe.mapOrElse
                (\dropdownContent ->
                    Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = model.state.openedDropdown == dropdownId }
                        (\m ->
                            button
                                ([ type_ "button"
                                 , id m.id
                                 , onClick (model.actions.headerDropdownClick m.id)
                                 , ariaExpanded m.isOpen
                                 , ariaHaspopup "true"
                                 , css [ "flex text-sm opacity-25", focus [ "outline-none" ] ]
                                 ]
                                    ++ (Track.openTableDropdown model.project |> track)
                                )
                                [ span [ class "sr-only" ] [ text "Open table settings" ]
                                , Icon.solid Icon.DotsVertical ""
                                ]
                        )
                        (\_ -> dropdownContent)
                )
                Html.none
        ]


viewColumns : Model msg -> Html msg
viewColumns model =
    let
        count : Int
        count =
            (model.columns |> List.length) + (model.hiddenColumns |> List.length)
    in
    Keyed.node "div" [] (model.columns |> List.indexedMap (\i c -> ( c.name, Lazy.lazy5 viewColumn model "" (i + 1 == count) i c )))


viewHiddenColumns : Model msg -> Html msg
viewHiddenColumns model =
    if model.hiddenColumns |> List.isEmpty then
        div [] []

    else
        let
            popoverId : HtmlId
            popoverId =
                model.id

            showPopover : Bool
            showPopover =
                model.state.openedPopover == popoverId && not model.state.showHiddenColumns

            popover : Html msg
            popover =
                if showPopover then
                    Keyed.node "div" [ class "py-2 rounded-lg bg-white shadow-md" ] (model.hiddenColumns |> List.map (\c -> ( c.name, Lazy.lazy5 viewColumn model "" False -1 c )))

                else
                    div [] []

            hiddenColumns : List ( String, Html msg )
            hiddenColumns =
                if model.state.showHiddenColumns then
                    model.hiddenColumns |> List.indexedMap (\i c -> ( c.name, Lazy.lazy5 viewColumn model "opacity-50" (i == List.length model.hiddenColumns - 1) -1 c ))

                else
                    []

            label : String
            label =
                model.hiddenColumns |> String.pluralizeL "more column"
        in
        Keyed.node "div"
            []
            (( label
             , div
                [ title label
                , Attributes.when model.conf.hover (onMouseEnter (model.actions.hiddenColumnsHover popoverId True))
                , Attributes.when model.conf.hover (onMouseLeave (model.actions.hiddenColumnsHover popoverId False))
                , Attributes.when model.conf.layout (onClick model.actions.hiddenColumnsClick)
                , class "h-6 pl-7 pr-2 whitespace-nowrap text-default-500 opacity-50 hover:opacity-100"
                , classList [ ( "cursor-pointer", model.conf.layout ) ]
                ]
                [ text ("... " ++ label) ]
                |> Popover.r popover showPopover
             )
                :: hiddenColumns
            )


viewColumn : Model msg -> TwClass -> Bool -> Int -> Column -> Html msg
viewColumn model styles isLast index column =
    div
        ([ title (column.name ++ " (" ++ column.kind ++ Bool.cond column.nullable "?" "" ++ ")")
         , Attributes.when model.conf.hover (onMouseEnter (model.actions.columnHover column.name True))
         , Attributes.when model.conf.hover (onMouseLeave (model.actions.columnHover column.name False))
         , Attributes.when model.conf.layout (stopDoubleClick (model.actions.columnDblClick column.name))
         , Attributes.when model.conf.layout (onContextMenu model.platform (model.actions.columnRightClick index column.name))
         , css
            [ "h-6 px-2 flex items-center align-middle whitespace-nowrap relative"
            , styles
            , Bool.cond (isHighlightedColumn model column) (batch [ text_500 model.state.color, bg_50 model.state.color ]) "text-default-500 bg-white"
            , Bool.cond isLast "rounded-b-lg" ""
            ]
         ]
            ++ (model.actions.columnClick |> Maybe.mapOrElse (\action -> [ onPointerUp model.platform (action column.name) ]) [])
        )
        [ viewColumnIcon model column |> viewColumnIconDropdown model column
        , viewColumnName model column
        , viewColumnKind model column
        ]


viewColumnIcon : Model msg -> Column -> Html msg
viewColumnIcon model column =
    let
        tooltip : String
        tooltip =
            [ Bool.maybe column.isPrimaryKey "Primary key"
            , Bool.maybe (column.outRelations |> List.nonEmpty) ("Foreign key to " ++ (column.outRelations |> List.head |> Maybe.mapOrElse (.column >> showColumnRef model.defaultSchema) ""))
            , Bool.maybe (column.uniques |> List.nonEmpty) ("Unique constraint for " ++ (column.uniques |> List.map .name |> String.join ", "))
            , Bool.maybe (column.indexes |> List.nonEmpty) ("Indexed by " ++ (column.indexes |> List.map .name |> String.join ", "))
            , Bool.maybe (column.checks |> List.nonEmpty) ("In checks " ++ (column.checks |> List.map .name |> String.join ", "))
            ]
                |> List.filterMap (\a -> a)
                |> String.join ", "
    in
    if column.outRelations |> List.nonEmpty then
        if (column.outRelations |> List.filter .tableShown |> List.nonEmpty) || not model.conf.layout then
            div []
                [ Icon.solid Icons.columns.foreignKey "w-4 h-4" |> Tooltip.t tooltip ]

        else
            div ([ css [ "cursor-pointer", text_500 model.state.color ], onClick (model.actions.relationsIconClick column.outRelations True) ] ++ (Track.showTableWithForeignKey model.project |> track))
                [ Icon.solid Icons.columns.foreignKey "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.isPrimaryKey then
        div [] [ Icon.solid Icons.columns.primaryKey "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.uniques |> List.nonEmpty then
        div [] [ Icon.solid Icons.columns.unique "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.indexes |> List.nonEmpty then
        div [] [ Icon.solid Icons.columns.index "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.checks |> List.nonEmpty then
        div [] [ Icon.solid Icons.columns.check "w-4 h-4" |> Tooltip.t tooltip ]

    else
        div [] [ Icon.solid Icon.Empty "w-4 h-4" ]


viewColumnIconDropdown : Model msg -> Column -> Html msg -> Html msg
viewColumnIconDropdown model column icon =
    let
        dropdownId : HtmlId
        dropdownId =
            model.id ++ "-" ++ column.name ++ "-dropdown"

        tablesToShow : List Relation
        tablesToShow =
            column.inRelations |> List.filterNot .tableShown
    in
    if List.isEmpty column.inRelations || not model.conf.layout then
        div [] [ button [ type_ "button", id dropdownId, css [ "cursor-default", focus [ "outline-none" ] ] ] [ icon ] ]

    else
        Dropdown.dropdown { id = dropdownId, direction = BottomRight, isOpen = model.state.openedDropdown == dropdownId }
            (\m ->
                button
                    ([ type_ "button"
                     , id m.id
                     , onClick (model.actions.headerDropdownClick m.id)
                     , ariaExpanded m.isOpen
                     , ariaHaspopup "true"
                     , css [ Bool.cond (tablesToShow |> List.isEmpty) "" (text_500 model.state.color), focus [ "outline-none" ] ]
                     ]
                        ++ (Track.openIncomingRelationsDropdown model.project |> track)
                    )
                    [ icon ]
            )
            (\_ ->
                div []
                    ((column.inRelations
                        |> List.groupBy (\r -> r.column.schema ++ "-" ++ r.column.table)
                        |> Dict.values
                        |> List.filterMap (List.sortBy (.column >> .column) >> Nel.fromList)
                        |> List.map
                            (\rels ->
                                let
                                    content : List (Html msg)
                                    content =
                                        [ Icon.solid Icons.columns.foreignKey "inline"
                                        , bText (showTableRef model.defaultSchema { schema = rels.head.column.schema, table = rels.head.column.table })
                                        , text ("." ++ (rels |> Nel.toList |> List.map (\r -> r.column.column ++ Bool.cond r.nullable "?" "") |> String.join ", "))
                                        ]
                                in
                                if rels.head.tableShown then
                                    ContextMenu.btnDisabled "py-1" content

                                else
                                    viewColumnIconDropdownItem model.project (model.actions.relationsIconClick [ rels.head ] False) content
                            )
                     )
                        ++ (if List.length tablesToShow > 1 then
                                [ viewColumnIconDropdownItem model.project (model.actions.relationsIconClick tablesToShow False) [ text ("Show all (" ++ (tablesToShow |> String.pluralizeL "table") ++ ")") ] ]

                            else
                                []
                           )
                    )
            )


viewColumnIconDropdownItem : ProjectInfo -> msg -> List (Html msg) -> Html msg
viewColumnIconDropdownItem project message content =
    button
        ([ type_ "button", onClick message, role "menuitem", tabindex -1, css [ "py-1 block w-full text-left", focus [ "outline-none" ], ContextMenu.itemStyles ] ]
            ++ (Track.showTableWithIncomingRelationsDropdown project |> track)
        )
        content


viewColumnName : Model msg -> Column -> Html msg
viewColumnName model column =
    div [ css [ "ml-1 flex flex-grow", Bool.cond column.isPrimaryKey "font-bold" "" ] ]
        ([ text column.name ]
            |> List.appendOn column.comment viewComment
            |> List.appendOn column.notes (viewNotes model (Just column.name))
        )


viewComment : String -> Html msg
viewComment comment =
    Icon.outline Icons.comment "w-4 ml-1 opacity-50" |> Tooltip.t comment


viewNotes : Model msg -> Maybe String -> String -> Html msg
viewNotes model column notes =
    span
        [ Attributes.when model.conf.layout (onClick (model.actions.notesClick column))
        , classList [ ( "cursor-pointer", model.conf.layout ) ]
        ]
        [ Icon.outline Icons.notes "w-4 ml-1 opacity-50" |> Tooltip.t notes ]


viewColumnKind : Model msg -> Column -> Html msg
viewColumnKind model column =
    let
        opacity : TwClass
        opacity =
            Bool.cond (isHighlightedColumn model column) "opacity-100" "opacity-50"

        tooltip : Maybe String
        tooltip =
            [ column.kindDetails
            , column.default |> Maybe.map (\default -> "Default value: " ++ default)
            ]
                |> List.filterMap identity
                |> String.join " / "
                |> String.nonEmptyMaybe

        value : Html msg
        value =
            tooltip
                |> Maybe.mapOrElse
                    (\content -> span [ css [ "underline", opacity ] ] [ text column.kind ] |> Tooltip.t content)
                    (span [ class opacity ] [ text column.kind ])

        nullable : List (Html msg)
        nullable =
            if column.nullable then
                [ span [ class opacity ] [ text "?" ] |> Tooltip.t "nullable" ]

            else
                [ span [ class "opacity-0" ] [ text "?" ] ]
    in
    div [ class "ml-1" ] (value :: nullable)


showTableRef : SchemaName -> TableRef -> String
showTableRef defaultSchema ref =
    if ref.schema == defaultSchema || ref.schema == Conf.schema.empty then
        ref.table

    else
        ref.schema ++ "." ++ ref.table


showColumnRef : SchemaName -> ColumnRef -> String
showColumnRef defaultSchema ref =
    if ref.schema == defaultSchema || ref.schema == Conf.schema.empty then
        ref.table ++ "." ++ ref.column

    else
        ref.schema ++ "." ++ ref.table ++ "." ++ ref.column


isHighlightedColumn : Model msg -> Column -> Bool
isHighlightedColumn model column =
    model.state.highlightedColumns |> Set.member column.name



-- DOCUMENTATION


type alias SharedDocState x =
    { x | tableDocState : DocState }


type alias DocState =
    State


initDocState : DocState
initDocState =
    sample.state


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | tableDocState = s.tableDocState |> transform })


sampleColumn : Column
sampleColumn =
    { index = 0, name = "", kind = "", kindDetails = Nothing, nullable = False, default = Nothing, comment = Nothing, notes = Nothing, isPrimaryKey = False, inRelations = [], outRelations = [], uniques = [], indexes = [], checks = [] }


sample : Model (Msg x)
sample =
    { id = "table-public-users"
    , ref = { schema = "demo", table = "users" }
    , label = "users"
    , isView = False
    , comment = Nothing
    , notes = Nothing
    , columns =
        [ { sampleColumn | name = "id", kind = "integer", isPrimaryKey = True, inRelations = [ { column = { schema = "demo", table = "accounts", column = "user" }, nullable = True, tableShown = False } ] }
        , { sampleColumn | name = "name", kind = "character varying(120)", comment = Just "Should be unique", notes = Just "A nice note", uniques = [ { name = "users_name_unique" } ] }
        , { sampleColumn | name = "email", kind = "character varying(120)", indexes = [ { name = "users_email_idx" } ] }
        , { sampleColumn | name = "bio", kind = "text", checks = [ { name = "users_bio_min_length" } ] }
        , { sampleColumn | name = "organization", kind = "integer", nullable = True, outRelations = [ { column = { schema = "demo", table = "organizations", column = "id" }, nullable = True, tableShown = False } ] }
        , { sampleColumn | name = "created", kind = "timestamp without time zone", default = Just "CURRENT_TIMESTAMP" }
        ]
    , hiddenColumns = []
    , dropdown =
        Just
            (div [ class "z-max" ]
                ([ { label = "Menu item 1", action = Simple { action = logAction "menu item 1", platform = Platform.PC, hotkeys = [] } }
                 , { label = "Menu item 2"
                   , action =
                        SubMenu
                            [ { label = "Menu item 2.1", action = logAction "menu item 2.1", platform = Platform.PC, hotkeys = [] }
                            , { label = "Menu item 2.2", action = logAction "menu item 2.2", platform = Platform.PC, hotkeys = [] }
                            ]
                   }
                 ]
                    |> List.map ContextMenu.btnSubmenu
                )
            )
    , platform = Platform.PC
    , state =
        { color = Tw.indigo
        , isHover = False
        , highlightedColumns = Set.empty
        , selected = False
        , dragging = False
        , collapsed = False
        , openedDropdown = ""
        , openedPopover = ""
        , showHiddenColumns = False
        }
    , actions =
        { hover = \on -> logAction ("hover " ++ Bool.cond on "on" " off")
        , headerClick = \_ -> logAction "headerClick"
        , headerDblClick = logAction "headerDblClick"
        , headerRightClick = \_ -> logAction "headerRightClick"
        , headerDropdownClick = \id -> logAction ("headerDropdownClick " ++ id)
        , columnHover = \c on -> logAction ("columnHover " ++ c ++ " " ++ Bool.cond on "on" " off")
        , columnClick = Just (\col _ -> logAction ("columnClick " ++ col))
        , columnDblClick = \col -> logAction ("columnDblClick " ++ col)
        , columnRightClick = \_ col _ -> logAction ("columnRightClick " ++ col)
        , notesClick = \col -> logAction ("notesClick " ++ (col |> Maybe.withDefault "table"))
        , relationsIconClick = \refs _ -> logAction ("relationsIconClick " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
        , hiddenColumnsHover = \id _ -> logAction ("hiddenColumnsHover " ++ id)
        , hiddenColumnsClick = logAction "hiddenColumnsClick"
        }
    , zoom = 1
    , project = { id = "", organization = Nothing }
    , conf = { layout = True, move = True, select = True, hover = True }
    , defaultSchema = Conf.schema.default
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Table"
        |> Chapter.renderStatefulComponentList
            [ ( "table"
              , \{ tableDocState } ->
                    table
                        { sample
                            | hiddenColumns = [ { sampleColumn | name = "created", kind = "timestamp without time zone" } ]
                            , state = tableDocState
                            , actions =
                                { hover = \on -> updateDocState (\s -> { s | isHover = on })
                                , headerClick = \_ -> updateDocState (\s -> { s | selected = not s.selected })
                                , headerDblClick = updateDocState (\s -> s)
                                , headerRightClick = \_ -> updateDocState (\s -> s)
                                , headerDropdownClick = \id -> updateDocState (\s -> { s | openedDropdown = Bool.cond (id == s.openedDropdown) "" id })
                                , columnHover = \c on -> updateDocState (\s -> { s | highlightedColumns = Bool.cond on (Set.fromList [ c ]) Set.empty })
                                , columnClick = Just (\col _ -> logAction ("columnClick " ++ col))
                                , columnDblClick = \col -> logAction ("columnDblClick " ++ col)
                                , columnRightClick = \_ col _ -> logAction ("columnRightClick " ++ col)
                                , notesClick = \col -> logAction ("notesClick " ++ (col |> Maybe.withDefault "table"))
                                , relationsIconClick = \refs _ -> logAction ("relationsIconClick " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
                                , hiddenColumnsHover = \id _ -> updateDocState (\s -> { s | openedPopover = id })
                                , hiddenColumnsClick = updateDocState (\s -> { s | showHiddenColumns = not s.showHiddenColumns })
                                }
                        }
              )
            , ( "states"
              , \_ ->
                    div [ css [ "flex flex-wrap gap-6" ] ]
                        ([ { sample | id = "View", isView = True }
                         , { sample | id = "With comment", comment = Just "Here is a comment" }
                         , { sample | id = "With notes", notes = Just "Here is some notes" }
                         , { sample | id = "Hover table", state = sample.state |> (\s -> { s | isHover = True }) }
                         , { sample | id = "Hover column", state = sample.state |> (\s -> { s | isHover = True, highlightedColumns = Set.fromList [ "name" ] }) }
                         , { sample | id = "Selected", state = sample.state |> (\s -> { s | selected = True }) }
                         , { sample | id = "Dragging", state = sample.state |> (\s -> { s | dragging = True }) }
                         , { sample | id = "Collapsed", state = sample.state |> (\s -> { s | collapsed = True }) }
                         , { sample | id = "Settings", state = sample.state |> (\s -> { s | openedDropdown = "Settings-settings" }) }
                         , { sample | id = "Hidden columns hidden", columns = sample.columns |> List.take 3, hiddenColumns = sample.columns |> List.drop 3, state = sample.state |> (\s -> { s | showHiddenColumns = False }) }
                         , { sample | id = "Hidden columns visible", columns = sample.columns |> List.take 3, hiddenColumns = sample.columns |> List.drop 3, state = sample.state |> (\s -> { s | showHiddenColumns = True }) }
                         ]
                            |> List.map (\model -> div [] [ text (model.id ++ ":"), br [] [], table model ])
                        )
              )
            ]
