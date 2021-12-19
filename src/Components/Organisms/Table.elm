module Components.Organisms.Table exposing (Actions, CheckConstraint, Column, ColumnRef, DocState, IndexConstraint, Model, SharedDocState, State, TableRef, UniqueConstraint, doc, initDocState, table)

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
import Html.Styled.Attributes exposing (css, id, type_)
import Html.Styled.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Html.Styled.Keyed as Keyed
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, onPointerUp)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor exposing (TwColorLevel(..))
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw


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
    }


type alias Column =
    { name : String
    , kind : String
    , nullable : Bool
    , default : Maybe String
    , comment : Maybe String
    , isPrimaryKey : Bool
    , inRelations : List ColumnRef
    , outRelations : List ColumnRef
    , uniques : List UniqueConstraint
    , indexes : List IndexConstraint
    , checks : List CheckConstraint
    }


type alias TableRef =
    { schema : String, table : String }


type alias ColumnRef =
    { schema : String, table : String, column : String }


type alias UniqueConstraint =
    { name : String }


type alias IndexConstraint =
    { name : String }


type alias CheckConstraint =
    { name : String }


type alias State =
    { color : Color
    , hover : Maybe TableRef
    , hoverColumn : Maybe ColumnRef
    , selected : Bool
    , dragging : Bool
    , openedDropdown : HtmlId
    , showHiddenColumns : Bool
    }


type alias Actions msg =
    { toggleHover : msg
    , toggleHoverColumn : String -> msg
    , toggleSelected : Bool -> msg
    , toggleSettings : HtmlId -> msg
    , toggleHiddenColumns : msg
    }


table : Model msg -> Html msg
table model =
    div
        [ id model.id
        , onMouseEnter model.actions.toggleHover
        , onMouseLeave model.actions.toggleHover
        , onPointerUp (\e -> model.actions.toggleSelected e.pointer.keys.ctrl)
        , css
            ([ Tw.inline_block, Tw.bg_white, Tw.rounded_lg, Tw.cursor_pointer, B.cond (isTableHover model) Tw.shadow_lg Tw.shadow_md ]
                ++ B.cond model.state.selected [ Tw.ring_4, Color.ring model.state.color L500 ] []
                ++ B.cond model.state.dragging [ Tw.transform, Tw.neg_rotate_3 ] []
            )
        ]
        [ model |> viewHeader
        , model |> viewColumns
        , model |> viewHiddenColumns
        ]


viewHeader : Model msg -> Html msg
viewHeader model =
    let
        dropdownId : HtmlId
        dropdownId =
            model.id ++ "-settings"
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
            , Color.border model.state.color L500
            , Tw.border_b
            , Color.border_b Color.default L200
            , Color.bg (B.cond (isTableHover model) model.state.color Color.default) L50
            ]
        ]
        [ if model.isView then
            div [ css [ Tw.flex_grow, Tw.text_center ] ] [ span [ css [ Tw.text_xl, Tw.italic, Tw.underline, Tu.underline_dotted ] ] [ text model.label ] |> Tooltip.top "This is a view" ]

          else
            div [ css [ Tw.flex_grow, Tw.text_center, Tw.text_xl ] ] [ text model.label ]
        , Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = model.state.openedDropdown == dropdownId }
            (\m ->
                button
                    [ type_ "button"
                    , id m.id
                    , onClick (model.actions.toggleSettings m.id)
                    , ariaExpanded m.isOpen
                    , ariaHaspopup True
                    , css [ Tw.flex, Tw.text_sm, Tw.opacity_25, Css.focus [ Tw.outline_none ] ]
                    ]
                    [ span [ css [ Tw.sr_only ] ] [ text "Open table settings" ]
                    , Icon.solid DotsVertical []
                    ]
            )
            (Dropdown.submenuButtons model.settings)
        ]


viewColumns : Model msg -> Html msg
viewColumns model =
    let
        count : Int
        count =
            (model.columns |> List.length) + (model.hiddenColumns |> List.length)
    in
    Keyed.node "div" [] (model.columns |> List.indexedMap (\i c -> ( c.name, viewColumn model (i + 1 == count) c )))


viewHiddenColumns : Model msg -> Html msg
viewHiddenColumns model =
    if model.hiddenColumns |> List.isEmpty then
        div [] []

    else
        div [ css [ Tw.m_2, Tw.p_2, Tw.bg_gray_100, Tw.rounded_lg ] ]
            [ div [ onClick model.actions.toggleHiddenColumns, css [ Tw.text_gray_400, Tw.uppercase, Tw.font_bold, Tw.text_sm ] ]
                [ text (model.hiddenColumns |> List.length |> S.pluralize "hidden column") ]
            , Keyed.node "div"
                [ css ([ Tw.rounded_lg, Tw.pt_2 ] ++ B.cond model.state.showHiddenColumns [] [ Tw.hidden ]) ]
                (model.hiddenColumns |> List.map (\c -> ( c.name, viewColumn model False c )))
            ]


viewColumn : Model msg -> Bool -> Column -> Html msg
viewColumn model isLast column =
    div
        [ onMouseEnter (model.actions.toggleHoverColumn column.name)
        , onMouseLeave (model.actions.toggleHoverColumn column.name)
        , css
            ([ Tw.flex, Tw.px_2, Tw.py_1, Tw.bg_white ]
                ++ B.cond (isColumnHover model column) [ Color.text model.state.color L500, Color.bg model.state.color L50 ] [ Color.text Color.default L500 ]
                ++ B.cond isLast [ Tw.rounded_b_lg ] []
            )
        ]
        [ viewColumnIconDropdown (viewColumnIcon column)
        , viewColumnName column
        , viewColumnKind model column
        ]


viewColumnIcon : Column -> Html msg
viewColumnIcon column =
    if column.isPrimaryKey then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid Key [] |> Tooltip.top "Primary key" ]

    else if column.outRelations |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid ExternalLink [] |> Tooltip.top ("Foreign key to " ++ (column.outRelations |> List.head |> M.mapOrElse formatRef "")) ]

    else if column.uniques |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid FingerPrint [] |> Tooltip.top ("Unique constraint in " ++ (column.uniques |> List.map .name |> String.join ", ")) ]

    else if column.indexes |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid SortDescending [] |> Tooltip.top ("Indexed by " ++ (column.indexes |> List.map .name |> String.join ", ")) ]

    else if column.checks |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ] ] [ Icon.solid Check [] |> Tooltip.top ("In checks " ++ (column.checks |> List.map .name |> String.join ", ")) ]

    else
        div [ css [ Tw.w_6, Tw.h_6 ] ] []


viewColumnIconDropdown : Html msg -> Html msg
viewColumnIconDropdown icon =
    div [] [ icon ]


viewColumnName : Column -> Html msg
viewColumnName column =
    div [ css ([ Tw.flex, Tw.flex_grow ] ++ B.cond column.isPrimaryKey [ Tw.font_bold ] []) ]
        ([ text column.name ] |> L.appendOn column.comment viewComment)


viewComment : String -> Html msg
viewComment comment =
    Icon.outline Chat [ Tw.w_4, Tw.ml_1, Tw.opacity_25 ] |> Tooltip.top comment


viewColumnKind : Model msg -> Column -> Html msg
viewColumnKind model column =
    let
        opacity : Css.Style
        opacity =
            B.cond (isColumnHover model column) Tw.opacity_100 Tw.opacity_25

        value : Html msg
        value =
            column.default
                |> M.mapOrElse
                    (\default -> span [ css [ opacity, Tw.underline ] ] [ text column.kind ] |> Tooltip.top ("default value: " ++ default))
                    (span [ css [ opacity ] ] [ text column.kind ])

        nullable : List (Html msg)
        nullable =
            if column.nullable then
                [ span [ css [ opacity ] ] [ text "?" ] |> Tooltip.top "nullable" ]

            else
                []
    in
    div [ css [ Tw.ml_1 ] ] (value :: nullable)


formatRef : ColumnRef -> String
formatRef ref =
    if ref.schema == "public" then
        ref.table ++ "." ++ ref.column

    else
        ref.schema ++ "." ++ ref.table ++ "." ++ ref.column


isTableHover : Model msg -> Bool
isTableHover model =
    model.state.hover |> M.has model.ref


isColumnHover : Model msg -> Column -> Bool
isColumnHover model column =
    model.state.hoverColumn |> M.has { schema = model.ref.schema, table = model.ref.table, column = column.name }



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
    { name = "", kind = "", nullable = False, default = Nothing, comment = Nothing, isPrimaryKey = False, inRelations = [], outRelations = [], uniques = [], indexes = [], checks = [] }


sample : Model (Msg x)
sample =
    { id = "table-public-users"
    , ref = { schema = "public", table = "users" }
    , label = "users"
    , isView = False
    , columns =
        [ { sampleColumn | name = "id", kind = "integer", isPrimaryKey = True, inRelations = [ { schema = "public", table = "accounts", column = "user" } ] }
        , { sampleColumn | name = "name", kind = "character varying(120)", comment = Just "Should be unique", uniques = [ { name = "users_name_unique" } ] }
        , { sampleColumn | name = "email", kind = "character varying(120)", indexes = [ { name = "users_email_idx" } ] }
        , { sampleColumn | name = "bio", kind = "text", checks = [ { name = "users_bio_min_length" } ] }
        , { sampleColumn | name = "organization", kind = "integer", nullable = True, outRelations = [ { schema = "public", table = "organizations", column = "id" } ] }
        , { sampleColumn | name = "created", kind = "timestamp without time zone", default = Just "CURRENT_TIMESTAMP" }
        ]
    , hiddenColumns = []
    , settings =
        [ { label = "Menu item 1", action = Right (logAction "menu item 1") }
        , { label = "Menu item 2"
          , action =
                Left
                    [ { label = "Menu item 2.1", action = logAction "menu item 2.1" }
                    , { label = "Menu item 2.2", action = logAction "menu item 2.2" }
                    ]
          }
        ]
    , state =
        { color = Color.indigo
        , hover = Nothing
        , hoverColumn = Nothing
        , selected = False
        , dragging = False
        , openedDropdown = ""
        , showHiddenColumns = False
        }
    , actions =
        { toggleHover = logAction "hover table"
        , toggleHoverColumn = \c -> logAction ("hover column " ++ c)
        , toggleSelected = \_ -> logAction "selected"
        , toggleSettings = \id -> logAction ("open " ++ id)
        , toggleHiddenColumns = logAction "hidden columns"
        }
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
                                { toggleHover = sample.ref |> (\ref -> updateDocState (\s -> { s | hover = B.cond (s.hover |> M.has ref) Nothing (Just ref) }))
                                , toggleHoverColumn = \c -> { schema = sample.ref.schema, table = sample.ref.table, column = c } |> (\ref -> updateDocState (\s -> { s | hoverColumn = B.cond (s.hoverColumn |> M.has ref) Nothing (Just ref) }))
                                , toggleSelected = \_ -> updateDocState (\s -> { s | selected = not s.selected })
                                , toggleSettings = \id -> updateDocState (\s -> { s | openedDropdown = B.cond (id == s.openedDropdown) "" id })
                                , toggleHiddenColumns = updateDocState (\s -> { s | showHiddenColumns = not s.showHiddenColumns })
                                }
                        }
              )
            , ( "states"
              , \_ ->
                    div [ css [ Tw.flex, Tw.flex_wrap, Tw.gap_6 ] ]
                        ([ { sample | id = "View", isView = True }
                         , { sample | id = "Hover table", state = sample.state |> (\s -> { s | hover = Just sample.ref }) }
                         , { sample | id = "Hover column", state = sample.state |> (\s -> { s | hover = Just sample.ref, hoverColumn = Just { schema = sample.ref.schema, table = sample.ref.table, column = "name" } }) }
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
