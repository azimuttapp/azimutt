module Components.Organisms.Table exposing (Actions, CheckConstraint, Column, ColumnRef, DocState, IndexConstraint, Model, Relation, SharedDocState, State, TableConf, TableRef, UniqueConstraint, doc, initDocState, table)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..), MenuItem)
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Popover as Popover
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Either exposing (Either(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Attribute, Html, br, button, div, span, text)
import Html.Attributes exposing (class, classList, id, style, tabindex, title, type_)
import Html.Events exposing (onClick, onDoubleClick, onMouseEnter, onMouseLeave)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as Bool
import Libs.Html as Html exposing (bText)
import Libs.Html.Attributes as Attributes exposing (ariaExpanded, ariaHaspopup, css, role, track)
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onPointerUp)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
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
    , settings : List (MenuItem msg)
    , state : State
    , actions : Actions msg
    , zoom : ZoomLevel
    , conf : TableConf
    }


type alias Column =
    { index : Int
    , name : String
    , kind : String
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


type alias TableRef =
    { schema : String, table : String }


type alias ColumnRef =
    { schema : String, table : String, column : String }


type alias Relation =
    { column : ColumnRef, nullable : Bool, tableShown : Bool }


type alias UniqueConstraint =
    { name : String }


type alias IndexConstraint =
    { name : String }


type alias CheckConstraint =
    { name : String }


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
    { hoverTable : Bool -> msg
    , hoverColumn : String -> Bool -> msg
    , clickHeader : Bool -> msg
    , clickColumn : Maybe (String -> Position -> msg)
    , clickNotes : Maybe String -> msg
    , contextMenuColumn : Int -> String -> PointerEvent -> msg
    , dblClickColumn : String -> msg
    , clickRelations : List Relation -> Bool -> msg
    , clickHiddenColumns : msg
    , clickDropdown : HtmlId -> msg
    , setPopover : HtmlId -> msg
    }


type alias TableConf =
    { layout : Bool, move : Bool, select : Bool, hover : Bool }


table : Model msg -> Html msg
table model =
    div
        [ id model.id
        , Attributes.when model.conf.hover (onMouseEnter (model.actions.hoverTable True))
        , Attributes.when model.conf.hover (onMouseLeave (model.actions.hoverTable False))
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
            Lazy.lazy viewColumns model
        , if model.state.collapsed then
            div [] []

          else
            Lazy.lazy viewHiddenColumns model
        ]


viewHeader : Model msg -> Html msg
viewHeader model =
    let
        dropdownId : HtmlId
        dropdownId =
            model.id ++ "-settings"

        headerTextSize : List (Attribute msg)
        headerTextSize =
            if model.zoom < 0.5 then
                [ style "font-size" (String.fromFloat (1.25 * 0.5 / model.zoom) ++ "rem") ]

            else
                []
    in
    div
        [ title model.label
        , css
            [ "flex items-center justify-items-center px-3 py-1 border-t-8 border-b border-b-default-200"
            , if model.state.collapsed then
                "rounded-lg"

              else
                "rounded-t-lg"
            , border_500 model.state.color
            , bg_50 (Bool.cond model.state.isHover model.state.color Tw.default)
            ]
        ]
        [ div
            [ Attributes.when model.conf.select (onPointerUp (\e -> model.actions.clickHeader e.ctrl))
            , class "flex-grow text-center"
            ]
            ([ if model.isView then
                span ([ class "text-xl italic underline decoration-dotted" ] ++ headerTextSize) [ text model.label ] |> Tooltip.t "This is a view"

               else
                span ([ class "text-xl" ] ++ headerTextSize) [ text model.label ]
             ]
                |> List.appendOn model.comment viewComment
                |> List.appendOn model.notes (viewNotes model Nothing)
            )
        , if model.settings |> List.nonEmpty then
            Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = model.state.openedDropdown == dropdownId }
                (\m ->
                    button
                        ([ type_ "button"
                         , id m.id
                         , onClick (model.actions.clickDropdown m.id)
                         , ariaExpanded m.isOpen
                         , ariaHaspopup True
                         , css [ "flex text-sm opacity-25", focus [ "outline-none" ] ]
                         ]
                            ++ track Track.openTableSettings
                        )
                        [ span [ class "sr-only" ] [ text "Open table settings" ]
                        , Icon.solid DotsVertical ""
                        ]
                )
                (\_ -> div [ class "z-max" ] (model.settings |> List.map ContextMenu.btnSubmenu))

          else
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
                , Attributes.when model.conf.hover (onMouseEnter (model.actions.setPopover popoverId))
                , Attributes.when model.conf.hover (onMouseLeave (model.actions.setPopover ""))
                , Attributes.when model.conf.layout (onClick model.actions.clickHiddenColumns)
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
         , Attributes.when model.conf.hover (onMouseEnter (model.actions.hoverColumn column.name True))
         , Attributes.when model.conf.hover (onMouseLeave (model.actions.hoverColumn column.name False))
         , Attributes.when model.conf.layout (onContextMenu (model.actions.contextMenuColumn index column.name))
         , Attributes.when model.conf.layout (onDoubleClick (model.actions.dblClickColumn column.name))
         , css
            [ "h-6 px-2 flex items-center align-middle whitespace-nowrap relative"
            , styles
            , Bool.cond (isHighlightedColumn model column) (batch [ text_500 model.state.color, bg_50 model.state.color ]) "text-default-500 bg-white"
            , Bool.cond isLast "rounded-b-lg" ""
            ]
         ]
            ++ (model.actions.clickColumn |> Maybe.mapOrElse (\action -> [ onPointerUp (.position >> action column.name) ]) [])
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
            , Bool.maybe (column.outRelations |> List.nonEmpty) ("Foreign key to " ++ (column.outRelations |> List.head |> Maybe.mapOrElse (.column >> formatColumnRef) ""))
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
                [ Icon.solid ExternalLink "w-4 h-4" |> Tooltip.t tooltip ]

        else
            div ([ css [ "cursor-pointer", text_500 model.state.color ], onClick (model.actions.clickRelations column.outRelations True) ] ++ track Track.showTableWithForeignKey)
                [ Icon.solid ExternalLink "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.isPrimaryKey then
        div [] [ Icon.solid Key "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.uniques |> List.nonEmpty then
        div [] [ Icon.solid FingerPrint "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.indexes |> List.nonEmpty then
        div [] [ Icon.solid SortDescending "w-4 h-4" |> Tooltip.t tooltip ]

    else if column.checks |> List.nonEmpty then
        div [] [ Icon.solid Check "w-4 h-4" |> Tooltip.t tooltip ]

    else
        div [] [ Icon.solid Empty "w-4 h-4" ]


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
                     , onClick (model.actions.clickDropdown m.id)
                     , ariaExpanded m.isOpen
                     , ariaHaspopup True
                     , css [ Bool.cond (tablesToShow |> List.isEmpty) "" (text_500 model.state.color), focus [ "outline-none" ] ]
                     ]
                        ++ track Track.openIncomingRelationsDropdown
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
                                        [ Icon.solid ExternalLink "inline"
                                        , bText (formatTableRef { schema = rels.head.column.schema, table = rels.head.column.table })
                                        , text ("." ++ (rels |> Nel.toList |> List.map (\r -> r.column.column ++ Bool.cond r.nullable "?" "") |> String.join ", "))
                                        ]
                                in
                                if rels.head.tableShown then
                                    ContextMenu.btnDisabled "py-1" content

                                else
                                    viewColumnIconDropdownItem (model.actions.clickRelations [ rels.head ] False) content
                            )
                     )
                        ++ (if List.length tablesToShow > 1 then
                                [ viewColumnIconDropdownItem (model.actions.clickRelations tablesToShow False) [ text ("Show all (" ++ (tablesToShow |> String.pluralizeL "table") ++ ")") ] ]

                            else
                                []
                           )
                    )
            )


viewColumnIconDropdownItem : msg -> List (Html msg) -> Html msg
viewColumnIconDropdownItem message content =
    button
        ([ type_ "button", onClick message, role "menuitem", tabindex -1, css [ "py-1 block w-full text-left", focus [ "outline-none" ], ContextMenu.itemStyles ] ]
            ++ track Track.showTableWithIncomingRelationsDropdown
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
    Icon.outline Chat "w-4 ml-1 opacity-50" |> Tooltip.t comment


viewNotes : Model msg -> Maybe String -> String -> Html msg
viewNotes model column notes =
    span
        [ Attributes.when model.conf.layout (onClick (model.actions.clickNotes column))
        , classList [ ( "cursor-pointer", model.conf.layout ) ]
        ]
        [ Icon.outline DocumentText "w-4 ml-1 opacity-50" |> Tooltip.t notes ]


viewColumnKind : Model msg -> Column -> Html msg
viewColumnKind model column =
    let
        opacity : TwClass
        opacity =
            Bool.cond (isHighlightedColumn model column) "opacity-100" "opacity-50"

        value : Html msg
        value =
            column.default
                |> Maybe.mapOrElse
                    (\default -> span [ css [ "underline", opacity ] ] [ text column.kind ] |> Tooltip.t ("default value: " ++ default))
                    (span [ class opacity ] [ text column.kind ])

        nullable : List (Html msg)
        nullable =
            if column.nullable then
                [ span [ class opacity ] [ text "?" ] |> Tooltip.t "nullable" ]

            else
                [ span [ class "opacity-0" ] [ text "?" ] ]
    in
    div [ class "ml-1" ] (value :: nullable)


formatTableRef : TableRef -> String
formatTableRef ref =
    if ref.schema == Conf.schema.default then
        ref.table

    else
        ref.schema ++ "." ++ ref.table


formatColumnRef : ColumnRef -> String
formatColumnRef ref =
    if ref.schema == Conf.schema.default then
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
    { index = 0, name = "", kind = "", nullable = False, default = Nothing, comment = Nothing, notes = Nothing, isPrimaryKey = False, inRelations = [], outRelations = [], uniques = [], indexes = [], checks = [] }


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
    , settings =
        [ { label = "Menu item 1", action = Right { action = logAction "menu item 1", hotkey = Nothing } }
        , { label = "Menu item 2"
          , action =
                Left
                    [ { label = "Menu item 2.1", action = logAction "menu item 2.1", hotkey = Nothing }
                    , { label = "Menu item 2.2", action = logAction "menu item 2.2", hotkey = Nothing }
                    ]
          }
        ]
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
        { hoverTable = \h -> logAction ("hover table " ++ Bool.cond h "on" " off")
        , hoverColumn = \c h -> logAction ("hover column " ++ c ++ " " ++ Bool.cond h "on" " off")
        , clickHeader = \_ -> logAction "selected"
        , clickColumn = Nothing
        , clickNotes = \col -> logAction ("click notes: " ++ (col |> Maybe.withDefault "table"))
        , contextMenuColumn = \_ col _ -> logAction ("menu column: " ++ col)
        , dblClickColumn = \col -> logAction ("toggle column: " ++ col)
        , clickRelations = \refs _ -> logAction ("show tables: " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
        , clickHiddenColumns = logAction "click hidden columns"
        , clickDropdown = \id -> logAction ("open " ++ id)
        , setPopover = \id -> logAction ("hover hidden columns: " ++ id)
        }
    , zoom = 1
    , conf = { layout = True, move = True, select = True, hover = True }
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
                                { hoverTable = \h -> updateDocState (\s -> { s | isHover = h })
                                , hoverColumn = \c h -> updateDocState (\s -> { s | highlightedColumns = Bool.cond h (Set.fromList [ c ]) Set.empty })
                                , clickHeader = \_ -> updateDocState (\s -> { s | selected = not s.selected })
                                , clickColumn = Nothing
                                , clickNotes = \col -> logAction ("click notes: " ++ (col |> Maybe.withDefault "table"))
                                , contextMenuColumn = \_ col _ -> logAction ("menu column: " ++ col)
                                , dblClickColumn = \col -> logAction ("toggle column: " ++ col)
                                , clickRelations = \refs _ -> logAction ("show tables: " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
                                , clickHiddenColumns = updateDocState (\s -> { s | showHiddenColumns = not s.showHiddenColumns })
                                , clickDropdown = \id -> updateDocState (\s -> { s | openedDropdown = Bool.cond (id == s.openedDropdown) "" id })
                                , setPopover = \id -> updateDocState (\s -> { s | openedPopover = id })
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
