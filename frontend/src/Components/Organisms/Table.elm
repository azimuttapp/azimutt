module Components.Organisms.Table exposing (Actions, CheckConstraint, Column, ColumnName, ColumnRef, DocState, IndexConstraint, Model, NestedColumns(..), OrganizationId, ProjectId, ProjectInfo, Relation, SchemaName, SharedDocState, State, TableConf, TableName, TableRef, UniqueConstraint, doc, docInit, table)

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
import Html.Attributes exposing (class, classList, id, style, tabindex, title, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as Bool
import Libs.Html as Html exposing (bText)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css, role)
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onDblClick, onPointerUp)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.Uuid exposing (Uuid)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Nel as Nel exposing (Nel)
import Libs.String as String
import Libs.Tailwind as Tw exposing (Color, TwClass, batch, bg_50, border_500, focus, ring_500, text_500)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.Comment as Comment
import Set exposing (Set)


type alias Model msg =
    { id : HtmlId
    , ref : TableRef
    , label : String
    , isView : Bool
    , comment : Maybe String
    , notes : Maybe String
    , isDeprecated : Bool
    , columns : List Column
    , hiddenColumns : List Column
    , dropdown : Maybe (Html msg)
    , state : State
    , actions : Actions msg
    , zoom : ZoomLevel
    , conf : TableConf
    , platform : Platform
    , defaultSchema : SchemaName
    }


type alias TableRef =
    { schema : String, table : String }


type alias Column =
    { index : Int
    , path : ColumnPath
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
    , isDeprecated : Bool
    , children : Maybe NestedColumns
    }


type NestedColumns
    = NestedColumns Int (List Column)


type alias State =
    { color : Color
    , isHover : Bool
    , highlightedColumns : Set ColumnPathStr
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
    , columnHover : ColumnPath -> Bool -> msg
    , columnClick : Maybe (ColumnPath -> PointerEvent -> msg)
    , columnDblClick : ColumnPath -> msg
    , columnRightClick : Int -> ColumnPath -> PointerEvent -> msg
    , notesClick : Maybe ColumnPath -> msg
    , relationsIconClick : List Relation -> Bool -> msg
    , nestedIconClick : ColumnPath -> Bool -> msg
    , hiddenColumnsHover : HtmlId -> Bool -> msg
    , hiddenColumnsClick : msg
    }


type alias TableConf =
    { layout : Bool, move : Bool, select : Bool, hover : Bool }


type alias Relation =
    { column : ColumnRef, nullable : Bool, tableShown : Bool }


type alias ColumnRef =
    { schema : String, table : String, column : ColumnPath }


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
        ([ id model.id
         , css
            [ "inline-block bg-white rounded-lg"
            , Bool.cond model.state.isHover "shadow-lg" "shadow-md"
            , Bool.cond model.state.selected ("ring-4 " ++ ring_500 model.state.color) ""
            , Bool.cond model.state.dragging "cursor-move" ""
            ]
         ]
            ++ Bool.cond model.conf.hover [ onMouseEnter (model.actions.hover True), onMouseLeave (model.actions.hover False) ] []
        )
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
            ([ class "flex-grow text-center whitespace-nowrap" ]
                ++ Bool.cond model.conf.select [ onPointerUp model.actions.headerClick model.platform ] []
                ++ Bool.cond model.conf.layout [ onDblClick (\_ -> model.actions.headerDblClick) model.platform, onContextMenu model.actions.headerRightClick model.platform ] []
            )
            ([ if model.isView then
                span [ class "text-xl italic underline decoration-dotted", classList [ ( "line-through", model.isDeprecated ) ] ] [ text model.label ] |> Tooltip.t "This is a view"

               else
                span [ class "text-xl", classList [ ( "line-through", model.isDeprecated ) ] ] [ text model.label ]
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
                                [ type_ "button"
                                , id m.id
                                , onClick (model.actions.headerDropdownClick m.id)
                                , ariaExpanded m.isOpen
                                , ariaHaspopup "true"
                                , css [ "flex text-sm opacity-25", focus [ "outline-none" ] ]
                                ]
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
        columns : List ( Int, Column )
        columns =
            model.columns |> flattenColumns

        count : Int
        count =
            (columns |> List.length) + (model.hiddenColumns |> List.length)
    in
    Keyed.node "div" [] (columns |> List.indexedMap (\index ( i, c ) -> ( c.path |> ColumnPath.toString, Lazy.lazy5 viewColumn model "" (index + 1 == count) i c )))


flattenColumns : List Column -> List ( Int, Column )
flattenColumns columns =
    columns |> List.zipWithIndex |> List.concatMap (\( c, i ) -> ( i, c ) :: (c.children |> Maybe.mapOrElse (\(NestedColumns _ cols) -> cols |> flattenColumns) []))


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
                    Keyed.node "div" [ class "py-2 rounded-lg bg-white shadow-md" ] (model.hiddenColumns |> List.indexedMap (\i c -> ( c.path |> ColumnPath.toString, Lazy.lazy5 viewColumn model "" False i c )))

                else
                    div [] []

            hiddenColumns : List ( String, Html msg )
            hiddenColumns =
                if model.state.showHiddenColumns then
                    model.hiddenColumns |> List.indexedMap (\i c -> ( c.path |> ColumnPath.toString, Lazy.lazy5 viewColumn model "opacity-50" (i == List.length model.hiddenColumns - 1) i c ))

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
                ([ title label
                 , class "h-6 pl-7 pr-2 whitespace-nowrap text-default-500 opacity-50 hover:opacity-75"
                 , classList [ ( "cursor-pointer", model.conf.layout ) ]
                 ]
                    ++ Bool.cond model.conf.hover [ onMouseEnter (model.actions.hiddenColumnsHover popoverId True), onMouseLeave (model.actions.hiddenColumnsHover popoverId False) ] []
                    ++ Bool.cond model.conf.layout [ onClick model.actions.hiddenColumnsClick ] []
                )
                [ text ("... " ++ label) ]
                |> Popover.r popover showPopover
             )
                :: hiddenColumns
            )


viewColumn : Model msg -> TwClass -> Bool -> Int -> Column -> Html msg
viewColumn model styles isLast nestIndex column =
    div
        ([ title (ColumnPath.name column.path ++ " (" ++ column.kind ++ Bool.cond column.nullable "?" "" ++ ")")
         , css
            [ "h-6 flex items-center align-middle whitespace-nowrap relative"
            , styles
            , Bool.cond (isHighlightedColumn model column.path) (batch [ text_500 model.state.color, bg_50 model.state.color ]) "text-default-500 bg-white"
            , Bool.cond isLast "rounded-b-lg" ""
            ]
         , style "padding-left" ((column.path |> ColumnPath.parent |> Maybe.mapOrElse Nel.length 0 |> String.fromInt) ++ ".5rem")
         , style "padding-right" "0.5rem"
         ]
            ++ Bool.cond model.conf.hover [ onMouseEnter (model.actions.columnHover column.path True), onMouseLeave (model.actions.columnHover column.path False) ] []
            ++ Bool.cond model.conf.layout [ onDblClick (\_ -> model.actions.columnDblClick column.path) model.platform, onContextMenu (model.actions.columnRightClick nestIndex column.path) model.platform ] []
            ++ (model.actions.columnClick |> Maybe.mapOrElse (\action -> [ onPointerUp (action column.path) model.platform ]) [])
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
            , column.children |> Maybe.map (\(NestedColumns count _) -> "Has " ++ String.fromInt count ++ " nested columns")
            ]
                |> List.filterMap (\a -> a)
                |> String.join ", "
    in
    if column.outRelations |> List.nonEmpty then
        if (column.outRelations |> List.filter .tableShown |> List.nonEmpty) || not model.conf.layout then
            div [] [ Icon.solid Icons.columns.foreignKey "w-4 h-4" |> Tooltip.t tooltip ]

        else
            div [ css [ "cursor-pointer", text_500 model.state.color ], onClick (model.actions.relationsIconClick column.outRelations True) ]
                [ Icon.solid Icons.columns.foreignKey "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.isPrimaryKey then
        div [] [ Icon.solid Icons.columns.primaryKey "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.children /= Nothing then
        if column.children |> Maybe.mapOrElse (\(NestedColumns _ cols) -> cols |> List.isEmpty) True then
            div [ onClick (model.actions.nestedIconClick column.path True), class "cursor-pointer" ] [ Icon.solid Icons.columns.nested "w-4 h-4" |> Tooltip.t tooltip ]

        else
            div [ onClick (model.actions.nestedIconClick column.path False), class "cursor-pointer" ] [ Icon.solid Icons.columns.nestedOpen "w-4 h-4" |> Tooltip.t tooltip ]

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
            model.id ++ "-" ++ ColumnPath.toString column.path ++ "-dropdown"

        tablesToShow : List Relation
        tablesToShow =
            column.inRelations |> List.filterNot .tableShown |> List.groupBy (\c -> ( c.column.schema, c.column.table )) |> Dict.values |> List.filterMap List.head
    in
    if List.isEmpty column.inRelations || not model.conf.layout then
        div [] [ button [ type_ "button", id dropdownId, css [ "cursor-default", focus [ "outline-none" ] ] ] [ icon ] ]

    else
        Dropdown.dropdown { id = dropdownId, direction = BottomRight, isOpen = model.state.openedDropdown == dropdownId }
            (\m ->
                button
                    [ type_ "button"
                    , id m.id
                    , onClick (model.actions.headerDropdownClick m.id)
                    , ariaExpanded m.isOpen
                    , ariaHaspopup "true"
                    , css [ Bool.cond (tablesToShow |> List.isEmpty) "" (text_500 model.state.color), focus [ "outline-none" ] ]
                    ]
                    [ icon ]
            )
            (\_ ->
                div []
                    ((column.inRelations
                        |> List.groupBy (\r -> r.column.schema ++ "-" ++ r.column.table)
                        |> Dict.values
                        |> List.filterMap (List.sortBy (.column >> .column >> ColumnPath.toString) >> Nel.fromList)
                        |> List.map
                            (\rels ->
                                let
                                    content : List (Html msg)
                                    content =
                                        [ Icon.solid Icons.columns.foreignKey "inline"
                                        , bText (showTableRef model.defaultSchema { schema = rels.head.column.schema, table = rels.head.column.table })
                                        , text ("." ++ (rels |> Nel.toList |> List.map (\r -> ColumnPath.show r.column.column ++ Bool.cond r.nullable "?" "") |> String.join ", "))
                                        ]
                                in
                                if rels.head.tableShown then
                                    ContextMenu.btnDisabled "py-1" content

                                else
                                    viewColumnIconDropdownItem (model.actions.relationsIconClick [ rels.head ] False) content
                            )
                     )
                        ++ (if List.length tablesToShow > 1 then
                                [ viewColumnIconDropdownItem (model.actions.relationsIconClick tablesToShow False) [ text ("Show all (" ++ (tablesToShow |> String.pluralizeL "table") ++ ")") ] ]

                            else
                                []
                           )
                    )
            )


viewColumnIconDropdownItem : msg -> List (Html msg) -> Html msg
viewColumnIconDropdownItem message content =
    button [ type_ "button", onClick message, role "menuitem", tabindex -1, css [ "py-1 block w-full text-left", focus [ "outline-none" ], ContextMenu.itemStyles ] ] content


viewColumnName : Model msg -> Column -> Html msg
viewColumnName model column =
    div [ css [ "ml-1 flex flex-grow", Bool.cond column.isPrimaryKey "font-bold" "", Bool.cond column.isDeprecated "line-through" "" ] ]
        ([ text (ColumnPath.name column.path) ]
            |> List.appendOn column.comment viewComment
            |> List.appendOn column.notes (viewNotes model (Just column.path))
        )


viewComment : String -> Html msg
viewComment comment =
    Icon.outline Icons.comment "w-4 ml-1 opacity-50" |> Tooltip.t (Comment.short comment)


viewNotes : Model msg -> Maybe ColumnPath -> String -> Html msg
viewNotes model column notes =
    span ([ classList [ ( "cursor-pointer", model.conf.layout ) ] ] ++ Bool.cond model.conf.layout [ onClick (model.actions.notesClick column) ] [])
        [ Icon.outline Icons.notes "w-4 ml-1 opacity-50" ]
        |> Tooltip.t (Comment.short notes)


viewColumnKind : Model msg -> Column -> Html msg
viewColumnKind model column =
    let
        opacity : TwClass
        opacity =
            Bool.cond (isHighlightedColumn model column.path) "opacity-100" "opacity-50"

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
        ref.table ++ "." ++ ColumnPath.show ref.column

    else
        ref.schema ++ "." ++ ref.table ++ "." ++ ColumnPath.show ref.column


isHighlightedColumn : Model msg -> ColumnPath -> Bool
isHighlightedColumn model path =
    (model.state.highlightedColumns |> Set.member (path |> ColumnPath.toString)) || (path |> ColumnPath.parent |> Maybe.mapOrElse (isHighlightedColumn model) False)



-- DOCUMENTATION


type alias SharedDocState x =
    { x | tableDocState : DocState }


type alias DocState =
    State


docInit : DocState
docInit =
    sample.state


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | tableDocState = s.tableDocState |> transform })


sampleColumn : Column
sampleColumn =
    { index = 0, path = Nel "" [], kind = "", kindDetails = Nothing, nullable = False, default = Nothing, comment = Nothing, notes = Nothing, isPrimaryKey = False, inRelations = [], outRelations = [], uniques = [], indexes = [], checks = [], isDeprecated = False, children = Nothing }


sample : Model (Msg x)
sample =
    { id = "table-public-users"
    , ref = { schema = "demo", table = "users" }
    , label = "users"
    , isView = False
    , comment = Nothing
    , notes = Nothing
    , isDeprecated = False
    , columns =
        [ { sampleColumn | path = Nel "id" [], kind = "integer", isPrimaryKey = True, inRelations = [ { column = { schema = "demo", table = "accounts", column = ColumnPath.fromString "user" }, nullable = True, tableShown = False } ] }
        , { sampleColumn | path = Nel "name" [], kind = "character varying(120)", comment = Just "Should be unique", notes = Just "A nice note", uniques = [ { name = "users_name_unique" } ] }
        , { sampleColumn | path = Nel "email" [], kind = "character varying(120)", indexes = [ { name = "users_email_idx" } ] }
        , { sampleColumn | path = Nel "bio" [], kind = "text", checks = [ { name = "users_bio_min_length" } ] }
        , { sampleColumn | path = Nel "organization" [], kind = "integer", nullable = True, outRelations = [ { column = { schema = "demo", table = "organizations", column = ColumnPath.fromString "id" }, nullable = True, tableShown = False } ] }
        , { sampleColumn | path = Nel "plan" [], kind = "object", children = Just (NestedColumns 1 []) }
        , { sampleColumn | path = Nel "created" [], kind = "timestamp without time zone", default = Just "CURRENT_TIMESTAMP", isDeprecated = True }
        ]
    , hiddenColumns = []
    , dropdown =
        Just
            (div [ class "z-max" ]
                ([ { label = "Menu item 1", content = Simple { action = logAction "menu item 1" } }
                 , { label = "Menu item 2"
                   , content =
                        SubMenu
                            [ { label = "Menu item 2.1", action = logAction "menu item 2.1" }
                            , { label = "Menu item 2.2", action = logAction "menu item 2.2" }
                            ]
                            BottomRight
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
        , columnHover = \c on -> logAction ("columnHover " ++ ColumnPath.show c ++ " " ++ Bool.cond on "on" " off")
        , columnClick = Just (\col _ -> logAction ("columnClick " ++ ColumnPath.show col))
        , columnDblClick = \col -> logAction ("columnDblClick " ++ ColumnPath.show col)
        , columnRightClick = \_ col _ -> logAction ("columnRightClick " ++ ColumnPath.show col)
        , notesClick = \col -> logAction ("notesClick " ++ (col |> Maybe.mapOrElse ColumnPath.show "table"))
        , relationsIconClick = \refs _ -> logAction ("relationsIconClick " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
        , nestedIconClick = \path open -> logAction ("nestedIconClick " ++ (path |> ColumnPath.show) ++ " " ++ Bool.cond open "open" " close")
        , hiddenColumnsHover = \id _ -> logAction ("hiddenColumnsHover " ++ id)
        , hiddenColumnsClick = logAction "hiddenColumnsClick"
        }
    , zoom = 1
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
                            | hiddenColumns = [ { sampleColumn | path = Nel "created" [], kind = "timestamp without time zone" } ]
                            , state = tableDocState
                            , actions =
                                { hover = \on -> updateDocState (\s -> { s | isHover = on })
                                , headerClick = \_ -> updateDocState (\s -> { s | selected = not s.selected })
                                , headerDblClick = updateDocState (\s -> s)
                                , headerRightClick = \_ -> updateDocState (\s -> s)
                                , headerDropdownClick = \id -> updateDocState (\s -> { s | openedDropdown = Bool.cond (id == s.openedDropdown) "" id })
                                , columnHover = \c on -> updateDocState (\s -> { s | highlightedColumns = Bool.cond on (Set.fromList [ ColumnPath.toString c ]) Set.empty })
                                , columnClick = Just (\col _ -> logAction ("columnClick " ++ ColumnPath.show col))
                                , columnDblClick = \col -> logAction ("columnDblClick " ++ ColumnPath.show col)
                                , columnRightClick = \_ col _ -> logAction ("columnRightClick " ++ ColumnPath.show col)
                                , notesClick = \col -> logAction ("notesClick " ++ (col |> Maybe.mapOrElse ColumnPath.show "table"))
                                , relationsIconClick = \refs _ -> logAction ("relationsIconClick " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
                                , nestedIconClick = \col open -> logAction ("nestedIconClick " ++ ColumnPath.show col ++ " " ++ Bool.cond open "open" " close")
                                , hiddenColumnsHover = \id _ -> updateDocState (\s -> { s | openedPopover = id })
                                , hiddenColumnsClick = updateDocState (\s -> { s | showHiddenColumns = not s.showHiddenColumns })
                                }
                        }
              )
            , ( "states"
              , \_ ->
                    div [ css [ "flex flex-wrap gap-6" ] ]
                        ([ { sample | id = "View", isView = True }
                         , { sample | id = "With nested", columns = sample.columns |> List.map (\c -> Bool.cond (c.path == Nel "plan" []) { c | children = Just (NestedColumns 1 [ { sampleColumn | path = Nel "plan" [ "id" ], kind = "int" } ]) } c) }
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
