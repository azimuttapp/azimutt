module Components.Organisms.Table exposing (Actions, CheckConstraint, Column, ColumnRef, DocState, IndexConstraint, Model, Relation, SharedDocState, State, TableRef, UniqueConstraint, doc, initDocState, table)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Styles as Styles
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..), MenuItem)
import Components.Molecules.Tooltip as Tooltip
import Css
import Either exposing (Either(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, br, button, div, span, text)
import Html.Styled.Attributes exposing (css, id, tabindex, type_)
import Html.Styled.Events exposing (onClick, onDoubleClick, onMouseEnter, onMouseLeave)
import Html.Styled.Keyed as Keyed
import Html.Styled.Lazy as Lazy
import Libs.Bool as B
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, role, track)
import Libs.Html.Styled.Events exposing (onPointerUp)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Set exposing (Set)
import Tailwind.Utilities as Tw
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
            [ Tw.inline_block
            , Tw.bg_white
            , Tw.rounded_lg
            , Tw.cursor_pointer
            , B.cond model.state.isHover Tw.shadow_lg Tw.shadow_md
            , Tu.when model.state.selected [ Tw.ring_4, Color.ring model.state.color 500 ]

            {- , Tu.when model.state.dragging [ Tw.transform, Tw.neg_rotate_3 ] -}
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

        textSize : Css.Style
        textSize =
            if model.zoom < 0.5 then
                Tu.font (1.25 * 0.5 / model.zoom) "rem"

            else
                Tw.text_xl
    in
    div
        [ css
            [ Tw.flex
            , Tw.items_center
            , Tw.justify_items_center
            , Tw.px_3
            , Tw.py_1
            , Tw.rounded_t_lg
            , Tw.border_t_8
            , Color.border model.state.color 500
            , Tw.border_b
            , Color.border_b Color.default 200
            , Color.bg (B.cond model.state.isHover model.state.color Color.default) 50
            ]
        ]
        [ div [ onPointerUp (\e -> model.actions.clickHeader e.ctrl), css [ Tw.flex_grow, Tw.text_center ] ]
            [ if model.isView then
                span [ css [ textSize, Tw.italic, Tw.underline, Tu.underline_dotted ] ] [ text model.label ] |> Tooltip.t "This is a view"

              else
                span [ css [ textSize ] ] [ text model.label ]
            ]
        , Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = model.state.openedDropdown == dropdownId }
            (\m ->
                button
                    ([ type_ "button"
                     , id m.id
                     , onClick (model.actions.clickDropdown m.id)
                     , ariaExpanded m.isOpen
                     , ariaHaspopup True
                     , css [ Tw.flex, Tw.text_sm, Tw.opacity_25, Css.focus [ Tw.outline_none ] ]
                     ]
                        ++ track Track.openTableSettings
                    )
                    [ span [ css [ Tw.sr_only ] ] [ text "Open table settings" ]
                    , Icon.solid DotsVertical []
                    ]
            )
            (\_ -> div [ css [ Tu.z_max ] ] (model.settings |> List.map Dropdown.submenuButton))
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
        div [ css [ Tw.m_2, Tw.p_2, Tw.bg_gray_100, Tw.rounded_lg ] ]
            [ div [ onClick model.actions.clickHiddenColumns, css [ Tw.text_gray_400, Tw.uppercase, Tw.font_bold, Tw.text_sm ] ]
                [ text (model.hiddenColumns |> S.pluralizeL "hidden column") ]
            , Keyed.node "div"
                [ css [ Tw.rounded_lg, Tw.pt_2, Tu.unless model.state.showHiddenColumns [ Tw.hidden ] ] ]
                (model.hiddenColumns |> List.map (\c -> ( c.name, Lazy.lazy3 viewColumn model False c )))
            ]


viewColumn : Model msg -> Bool -> Column -> Html msg
viewColumn model isLast column =
    div
        ([ onMouseEnter (model.actions.hoverColumn column.name True)
         , onMouseLeave (model.actions.hoverColumn column.name False)
         , onDoubleClick (model.actions.dblClickColumn column.name)
         , css [ Tw.items_center, Tw.flex, Tw.px_2, Tw.bg_white, Css.batch (B.cond (isHighlightedColumn model column) [ Color.text model.state.color 500, Color.bg model.state.color 50 ] [ Color.text Color.default 500 ]), Tu.when isLast [ Tw.rounded_b_lg ] ]
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
        div ([ css [ Tw.w_6, Tw.h_6 ], onClick (model.actions.clickRelations column.outRelations) ] ++ track Track.showTableWithForeignKey) [ Icon.solid ExternalLink [ Tw.pt_2 ] |> Tooltip.t ("Foreign key to " ++ (column.outRelations |> List.head |> M.mapOrElse (.column >> formatColumnRef) "")) ]

    else if column.isPrimaryKey then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid Key [ Tw.pt_2 ] |> Tooltip.t "Primary key" ]

    else if column.uniques |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid FingerPrint [ Tw.pt_2 ] |> Tooltip.t ("Unique constraint for " ++ (column.uniques |> List.map .name |> String.join ", ")) ]

    else if column.indexes |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid SortDescending [ Tw.pt_2 ] |> Tooltip.t ("Indexed by " ++ (column.indexes |> List.map .name |> String.join ", ")) ]

    else if column.checks |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid Check [ Tw.pt_2 ] |> Tooltip.t ("In checks " ++ (column.checks |> List.map .name |> String.join ", ")) ]

    else
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid Empty [ Tw.pt_2 ] ]


viewColumnIconDropdown : Model msg -> Column -> Html msg -> Html msg
viewColumnIconDropdown model column icon =
    let
        dropdownId : HtmlId
        dropdownId =
            model.id ++ "-" ++ column.name ++ "-dropdown"
    in
    if column.inRelations |> List.isEmpty then
        div [] [ button [ type_ "button", id dropdownId, css [ Css.focus [ Tw.outline_none ] ] ] [ icon ] ]

    else
        Dropdown.dropdown { id = dropdownId, direction = BottomRight, isOpen = model.state.openedDropdown == dropdownId }
            (\m ->
                button
                    ([ type_ "button"
                     , id m.id
                     , onClick (model.actions.clickDropdown m.id)
                     , ariaExpanded m.isOpen
                     , ariaHaspopup True
                     , css [ Css.focus [ Tw.outline_none ] ]
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
                                        [ Icon.solid ExternalLink [ Tw.inline ]
                                        , bText (formatTableRef { schema = r.column.schema, table = r.column.table })
                                        , text ("." ++ r.column.column ++ B.cond r.nullable "?" "")
                                        ]
                                in
                                if r.tableShown then
                                    Dropdown.btnDisabled [ Tw.py_1 ] content

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
        ([ type_ "button"
         , onClick message
         , role "menuitem"
         , tabindex -1
         , css [ Tw.py_1, Tw.block, Tw.w_full, Tw.text_left, Dropdown.itemStyles, Css.focus [ Tw.outline_none ] ]
         ]
            ++ track Track.showTableWithIncomingRelationsDropdown
        )
        content


viewColumnName : Column -> Html msg
viewColumnName column =
    div [ css [ Tw.flex, Tw.flex_grow, Tu.when column.isPrimaryKey [ Tw.font_bold ] ] ]
        ([ text column.name ] |> L.appendOn column.comment viewComment)


viewComment : String -> Html msg
viewComment comment =
    Icon.outline Chat [ Tw.w_4, Tw.ml_1, Tw.opacity_25 ] |> Tooltip.t comment


viewColumnKind : Model msg -> Column -> Html msg
viewColumnKind model column =
    let
        opacity : Css.Style
        opacity =
            B.cond (isHighlightedColumn model column) Tw.opacity_100 Tw.opacity_25

        value : Html msg
        value =
            column.default
                |> M.mapOrElse
                    (\default -> span [ css [ opacity, Tw.underline ] ] [ text column.kind ] |> Tooltip.t ("default value: " ++ default))
                    (span [ css [ opacity ] ] [ text column.kind ])

        nullable : List (Html msg)
        nullable =
            if column.nullable then
                [ span [ css [ opacity ] ] [ text "?" ] |> Tooltip.t "nullable" ]

            else
                []
    in
    div [ css [ Tw.ml_1 ] ] (value :: nullable)


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
        { color = Color.indigo
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
                    div [ css [ Tw.flex, Tw.flex_wrap, Tw.gap_6 ] ]
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
            , ( "global css", \_ -> div [] [ Styles.global, text "Global styles are needed for tooltip reveal and dropdown submenu" ] )
            ]
