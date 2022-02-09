module Components.Organisms.Table exposing (Actions, CheckConstraint, Column, ColumnRef, DocState, IndexConstraint, Model, Relation, SharedDocState, State, TableRef, UniqueConstraint, doc, initDocState, table)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..), MenuItem)
import Components.Molecules.Tooltip as Tooltip
import Either exposing (Either(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Attribute, Html, br, button, div, span, text)
import Html.Attributes exposing (class, id, style, tabindex, type_)
import Html.Events exposing (onClick, onDoubleClick, onMouseEnter, onMouseLeave)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css, role, track)
import Libs.Html.Events exposing (onPointerUp)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.String as S
import Libs.Tailwind as Tw exposing (Color, TwClass, batch, bg_50, border_500, focus, ring_500, text_500)
import Set exposing (Set)
import Track


type alias Model msg =
    { id : HtmlId
    , ref : TableRef
    , label : String
    , isView : Bool
    , columns : List Column
    , hiddenColumns : List Column
    , settings : List (MenuItem msg)
    , state : State
    , actions : Actions msg
    , zoom : ZoomLevel
    }


type alias Column =
    { index : Int
    , name : String
    , kind : String
    , nullable : Bool
    , default : Maybe String
    , comment : Maybe String
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
    , dragging : Bool
    , openedDropdown : HtmlId
    , showHiddenColumns : Bool
    }


type alias Actions msg =
    { hoverTable : Bool -> msg
    , hoverColumn : String -> Bool -> msg
    , clickHeader : Bool -> msg
    , clickColumn : Maybe (String -> Position -> msg)
    , dblClickColumn : String -> msg
    , clickRelations : List Relation -> msg
    , clickHiddenColumns : msg
    , clickDropdown : HtmlId -> msg
    }


table : Model msg -> Html msg
table model =
    div
        [ id model.id
        , onMouseEnter (model.actions.hoverTable True)
        , onMouseLeave (model.actions.hoverTable False)
        , css
            [ "inline-block bg-white rounded-lg"
            , B.cond model.state.isHover "shadow-lg" "shadow-md"
            , B.cond model.state.selected ("ring-4 " ++ ring_500 model.state.color) ""
            , B.cond model.state.dragging "cursor-move" ""
            ]
        ]
        [ Lazy.lazy viewHeader model
        , Lazy.lazy viewColumns model
        , Lazy.lazy viewHiddenColumns model
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
        [ css
            [ "flex items-center justify-items-center px-3 py-1 rounded-t-lg border-t-8 border-b border-b-default-200"
            , border_500 model.state.color
            , bg_50 (B.cond model.state.isHover model.state.color Tw.default)
            ]
        ]
        [ div [ onPointerUp (\e -> model.actions.clickHeader e.ctrl), class "flex-grow text-center" ]
            [ if model.isView then
                span ([ class "text-xl italic underline decoration-dotted" ] ++ headerTextSize) [ text model.label ] |> Tooltip.t "This is a view"

              else
                span ([ class "text-xl" ] ++ headerTextSize) [ text model.label ]
            ]
        , Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = model.state.openedDropdown == dropdownId }
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
            (\_ -> div [ class "z-max" ] (model.settings |> List.map Dropdown.submenuButton))
        ]


viewColumns : Model msg -> Html msg
viewColumns model =
    let
        count : Int
        count =
            (model.columns |> List.length) + (model.hiddenColumns |> List.length)
    in
    Keyed.node "div" [] (model.columns |> List.indexedMap (\i c -> ( c.name, Lazy.lazy3 viewColumn model (i + 1 == count) c )))


viewHiddenColumns : Model msg -> Html msg
viewHiddenColumns model =
    if model.hiddenColumns |> List.isEmpty then
        div [] []

    else
        div [ class "m-2 p-2 bg-gray-100 rounded-lg" ]
            [ div [ onClick model.actions.clickHiddenColumns, class "text-gray-400 uppercase font-bold text-sm cursor-pointer" ]
                [ text (model.hiddenColumns |> S.pluralizeL "hidden column") ]
            , Keyed.node "div"
                [ css [ "rounded-lg pt-2", B.cond model.state.showHiddenColumns "" "hidden" ] ]
                (model.hiddenColumns |> List.map (\c -> ( c.name, Lazy.lazy3 viewColumn model False c )))
            ]


viewColumn : Model msg -> Bool -> Column -> Html msg
viewColumn model isLast column =
    div
        ([ onMouseEnter (model.actions.hoverColumn column.name True)
         , onMouseLeave (model.actions.hoverColumn column.name False)
         , onDoubleClick (model.actions.dblClickColumn column.name)
         , css
            [ "items-center flex px-2 whitespace-nowrap"
            , B.cond (isHighlightedColumn model column) (batch [ text_500 model.state.color, bg_50 model.state.color ]) "text-default-500 bg-white"
            , B.cond isLast "rounded-b-lg" ""
            ]
         ]
            ++ (model.actions.clickColumn |> M.mapOrElse (\action -> [ onPointerUp (.position >> action column.name) ]) [])
        )
        [ viewColumnIcon model column |> viewColumnIconDropdown model column
        , viewColumnName column
        , viewColumnKind model column
        ]


viewColumnIcon : Model msg -> Column -> Html msg
viewColumnIcon model column =
    if column.outRelations |> L.nonEmpty then
        div ([ class "w-6 h-6 cursor-pointer", onClick (model.actions.clickRelations column.outRelations) ] ++ track Track.showTableWithForeignKey)
            [ Icon.solid ExternalLink "pt-2" |> Tooltip.t ("Foreign key to " ++ (column.outRelations |> List.head |> M.mapOrElse (.column >> formatColumnRef) "")) ]

    else if column.isPrimaryKey then
        div [ class "w-6 h-6" ] [ Icon.solid Key "pt-2" |> Tooltip.t "Primary key" ]

    else if column.uniques |> L.nonEmpty then
        div [ class "w-6 h-6" ] [ Icon.solid FingerPrint "pt-2" |> Tooltip.t ("Unique constraint for " ++ (column.uniques |> List.map .name |> String.join ", ")) ]

    else if column.indexes |> L.nonEmpty then
        div [ class "w-6 h-6" ] [ Icon.solid SortDescending "pt-2" |> Tooltip.t ("Indexed by " ++ (column.indexes |> List.map .name |> String.join ", ")) ]

    else if column.checks |> L.nonEmpty then
        div [ class "w-6 h-6" ] [ Icon.solid Check "pt-2" |> Tooltip.t ("In checks " ++ (column.checks |> List.map .name |> String.join ", ")) ]

    else
        div [ class "w-6 h-6" ] [ Icon.solid Empty "pt-2" ]


viewColumnIconDropdown : Model msg -> Column -> Html msg -> Html msg
viewColumnIconDropdown model column icon =
    let
        dropdownId : HtmlId
        dropdownId =
            model.id ++ "-" ++ column.name ++ "-dropdown"
    in
    if column.inRelations |> List.isEmpty then
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
                     , css [ focus [ "outline-none" ] ]
                     ]
                        ++ track Track.openIncomingRelationsDropdown
                    )
                    [ icon ]
            )
            (\_ ->
                div []
                    ((column.inRelations
                        |> List.map
                            (\r ->
                                let
                                    content : List (Html msg)
                                    content =
                                        [ Icon.solid ExternalLink "inline"
                                        , bText (formatTableRef { schema = r.column.schema, table = r.column.table })
                                        , text ("." ++ r.column.column ++ B.cond r.nullable "?" "")
                                        ]
                                in
                                if r.tableShown then
                                    Dropdown.btnDisabled "py-1" content

                                else
                                    viewColumnIconDropdownItem (model.actions.clickRelations [ r ]) content
                            )
                     )
                        ++ (column.inRelations
                                |> List.filter (\r -> not r.tableShown)
                                |> (\relations ->
                                        if List.length relations > 1 then
                                            [ viewColumnIconDropdownItem (model.actions.clickRelations relations) [ text ("Show all (" ++ (relations |> S.pluralizeL "table") ++ ")") ] ]

                                        else
                                            []
                                   )
                           )
                    )
            )


viewColumnIconDropdownItem : msg -> List (Html msg) -> Html msg
viewColumnIconDropdownItem message content =
    button
        ([ type_ "button", onClick message, role "menuitem", tabindex -1, css [ "py-1 block w-full text-left", focus [ "outline-none" ], Dropdown.itemStyles ] ]
            ++ track Track.showTableWithIncomingRelationsDropdown
        )
        content


viewColumnName : Column -> Html msg
viewColumnName column =
    div [ css [ "flex flex-grow", B.cond column.isPrimaryKey "font-bold" "" ] ]
        ([ text column.name ] |> L.appendOn column.comment viewComment)


viewComment : String -> Html msg
viewComment comment =
    Icon.outline Chat "w-4 ml-1 opacity-50" |> Tooltip.t comment


viewColumnKind : Model msg -> Column -> Html msg
viewColumnKind model column =
    let
        opacity : TwClass
        opacity =
            B.cond (isHighlightedColumn model column) "opacity-100" "opacity-50"

        value : Html msg
        value =
            column.default
                |> M.mapOrElse
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
    if ref.schema == "public" then
        ref.table

    else
        ref.schema ++ "." ++ ref.table


formatColumnRef : ColumnRef -> String
formatColumnRef ref =
    if ref.schema == "public" then
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
    { index = 0, name = "", kind = "", nullable = False, default = Nothing, comment = Nothing, isPrimaryKey = False, inRelations = [], outRelations = [], uniques = [], indexes = [], checks = [] }


sample : Model (Msg x)
sample =
    { id = "table-public-users"
    , ref = { schema = "public", table = "users" }
    , label = "users"
    , isView = False
    , columns =
        [ { sampleColumn | name = "id", kind = "integer", isPrimaryKey = True, inRelations = [ { column = { schema = "public", table = "accounts", column = "user" }, nullable = True, tableShown = False } ] }
        , { sampleColumn | name = "name", kind = "character varying(120)", comment = Just "Should be unique", uniques = [ { name = "users_name_unique" } ] }
        , { sampleColumn | name = "email", kind = "character varying(120)", indexes = [ { name = "users_email_idx" } ] }
        , { sampleColumn | name = "bio", kind = "text", checks = [ { name = "users_bio_min_length" } ] }
        , { sampleColumn | name = "organization", kind = "integer", nullable = True, outRelations = [ { column = { schema = "public", table = "organizations", column = "id" }, nullable = True, tableShown = False } ] }
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
        , openedDropdown = ""
        , showHiddenColumns = False
        }
    , actions =
        { hoverTable = \h -> logAction ("hover table " ++ B.cond h "on" " off")
        , hoverColumn = \c h -> logAction ("hover column " ++ c ++ " " ++ B.cond h "on" " off")
        , clickHeader = \_ -> logAction "selected"
        , clickColumn = Nothing
        , dblClickColumn = \col -> logAction ("toggle column: " ++ col)
        , clickRelations = \refs -> logAction ("show tables: " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
        , clickHiddenColumns = logAction "hidden columns"
        , clickDropdown = \id -> logAction ("open " ++ id)
        }
    , zoom = 1
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
                                , hoverColumn = \c h -> updateDocState (\s -> { s | highlightedColumns = B.cond h (Set.fromList [ c ]) Set.empty })
                                , clickHeader = \_ -> updateDocState (\s -> { s | selected = not s.selected })
                                , clickColumn = Nothing
                                , dblClickColumn = \col -> logAction ("toggle column: " ++ col)
                                , clickRelations = \refs -> logAction ("show tables: " ++ (refs |> List.map (\r -> r.column.schema ++ "." ++ r.column.table) |> String.join ", "))
                                , clickHiddenColumns = updateDocState (\s -> { s | showHiddenColumns = not s.showHiddenColumns })
                                , clickDropdown = \id -> updateDocState (\s -> { s | openedDropdown = B.cond (id == s.openedDropdown) "" id })
                                }
                        }
              )
            , ( "states"
              , \_ ->
                    div [ css [ "flex flex-wrap gap-6" ] ]
                        ([ { sample | id = "View", isView = True }
                         , { sample | id = "Hover table", state = sample.state |> (\s -> { s | isHover = True }) }
                         , { sample | id = "Hover column", state = sample.state |> (\s -> { s | isHover = True, highlightedColumns = Set.fromList [ "name" ] }) }
                         , { sample | id = "Selected", state = sample.state |> (\s -> { s | selected = True }) }
                         , { sample | id = "Dragging", state = sample.state |> (\s -> { s | dragging = True }) }
                         , { sample | id = "Settings", state = sample.state |> (\s -> { s | openedDropdown = "Settings-settings" }) }
                         , { sample | id = "Hidden columns hidden", columns = sample.columns |> List.take 3, hiddenColumns = sample.columns |> List.drop 3, state = sample.state |> (\s -> { s | showHiddenColumns = False }) }
                         , { sample | id = "Hidden columns visible", columns = sample.columns |> List.take 3, hiddenColumns = sample.columns |> List.drop 3, state = sample.state |> (\s -> { s | showHiddenColumns = True }) }
                         ]
                            |> List.map (\model -> div [] [ text (model.id ++ ":"), br [] [], table model ])
                        )
              )
            ]
