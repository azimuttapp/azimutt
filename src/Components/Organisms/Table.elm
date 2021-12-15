module Components.Organisms.Table exposing (Actions, CheckConstraint, Column, ColumnRef, DocState, IndexConstraint, Model, SharedDocState, State, TableRef, UniqueConstraint, doc, initDocState, table)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Attribute, Html, a, br, button, div, span, text)
import Html.Styled.Attributes exposing (css, href, id, tabindex, title, type_)
import Html.Styled.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Html.Styled.Keyed as Keyed
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, onPointerUp, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor exposing (TwColorLevel(..))
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw


type alias Model msg =
    { id : HtmlId
    , ref : TableRef
    , label : String
    , isView : Bool
    , columns : List Column
    , hiddenColumns : List Column
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
    , openedDropdown : HtmlId
    }


type alias Actions msg =
    { toggleSettings : HtmlId -> msg
    , toggleHover : msg
    , toggleHoverColumn : String -> msg
    , toggleSelected : Bool -> msg
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

        labelAttrs : List (Attribute msg)
        labelAttrs =
            if model.isView then
                [ css [ Tw.flex_grow, Tw.text_center, Tw.text_xl, Tw.italic, Tw.underline, Tu.underline_dotted ], title "This is a view" ]

            else
                [ css [ Tw.flex_grow, Tw.text_center, Tw.text_xl ] ]
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
        [ div labelAttrs [ text model.label ]
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
            (\_ ->
                div [ css [ Tw.w_48 ] ]
                    ([ "Hide table", "Sort columns", "Hide columns", "Show columns", "Order", "Find path for this table" ]
                        |> List.map
                            (\action ->
                                a [ href "#", role "menuitem", tabindex -1, css [ Tw.block, Tw.py_2, Tw.px_4, Tw.text_sm, Tw.text_gray_700, Css.hover [ Tw.bg_gray_100 ] ] ] [ text action ]
                            )
                    )
            )
        ]


viewColumns : Model msg -> Html msg
viewColumns model =
    let
        count : Int
        count =
            (model.columns |> List.length) + (model.hiddenColumns |> List.length)
    in
    Keyed.node "div" [] (model.columns |> List.indexedMap (\i c -> ( c.name, viewColumn model (i + 1 == count) c )))


viewColumn : Model msg -> Bool -> Column -> Html msg
viewColumn model isLast column =
    div
        [ onMouseEnter (model.actions.toggleHoverColumn column.name)
        , onMouseLeave (model.actions.toggleHoverColumn column.name)
        , css
            ([ Tw.flex, Tw.px_2, Tw.py_1 ]
                ++ B.cond (isColumnHover model column) [ Color.text model.state.color L500, Color.bg Color.default L100 ] [ Color.text Color.default L500 ]
                ++ B.cond isLast [ Tw.rounded_b_lg ] []
            )
        ]
        [ viewColumnIconDropdown (viewColumnIcon column)
        , viewColumnName column
        , viewColumnKind model column
        ]


viewHiddenColumns : Model msg -> Html msg
viewHiddenColumns _ =
    div [] []


viewColumnIcon : Column -> Html msg
viewColumnIcon column =
    if column.isPrimaryKey then
        div [ css [ Tw.w_6, Tw.h_6 ], title "Primary key" ] [ Icon.solid Key [] ]

    else if column.outRelations |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ], title ("Foreign key to " ++ (column.outRelations |> List.head |> M.mapOrElse formatRef "")) ] [ Icon.solid ExternalLink [] ]

    else if column.uniques |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ], title ("Unique constraint in " ++ (column.uniques |> List.map .name |> String.join ", ")) ] [ Icon.solid FingerPrint [] ]

    else if column.indexes |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ], title ("Indexed by " ++ (column.indexes |> List.map .name |> String.join ", ")) ] [ Icon.solid SortDescending [] ]

    else if column.checks |> L.nonEmpty then
        div [ css [ Tw.w_6, Tw.h_6 ], title ("In checks " ++ (column.checks |> List.map .name |> String.join ", ")) ] [ Icon.solid Check [] ]

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
    span [ title comment, css [ Tw.opacity_25, Tw.ml_1 ] ] [ Icon.outline Chat [ Tw.w_4 ] ]


viewColumnKind : Model msg -> Column -> Html msg
viewColumnKind model column =
    let
        value : Html msg
        value =
            column.default
                |> M.mapOrElse
                    (\default -> span [ title ("default value: " ++ default), css [ Tw.underline ] ] [ text column.kind ])
                    (span [] [ text column.kind ])

        nullable : List (Html msg)
        nullable =
            if column.nullable then
                [ span [ title "nullable" ] [ text "?" ] ]

            else
                []
    in
    div [ css ([ Tw.ml_1 ] ++ B.cond (isColumnHover model column) [] [ Tw.opacity_25 ]) ] (value :: nullable)


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
    , state =
        { color = Color.indigo
        , hover = Nothing
        , hoverColumn = Nothing
        , selected = False
        , openedDropdown = ""
        }
    , actions =
        { toggleSettings = \id -> logAction ("open " ++ id)
        , toggleHover = logAction "hover table"
        , toggleHoverColumn = \c -> logAction ("hover column " ++ c)
        , toggleSelected = \_ -> logAction "selected"
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
                            | state = tableDocState
                            , actions =
                                { toggleSettings = \id -> updateDocState (\s -> { s | openedDropdown = B.cond (id == s.openedDropdown) "" id })
                                , toggleHover = sample.ref |> (\ref -> updateDocState (\s -> { s | hover = B.cond (s.hover |> M.has ref) Nothing (Just ref) }))
                                , toggleHoverColumn = \c -> { schema = sample.ref.schema, table = sample.ref.table, column = c } |> (\ref -> updateDocState (\s -> { s | hoverColumn = B.cond (s.hoverColumn |> M.has ref) Nothing (Just ref) }))
                                , toggleSelected = \_ -> updateDocState (\s -> { s | selected = not s.selected })
                                }
                        }
              )
            , ( "table states"
              , \_ ->
                    div [ css [ Tw.flex ] ]
                        ([ { sample | id = "View", isView = True }
                         , { sample | id = "Hover table", state = sample.state |> (\s -> { s | hover = Just sample.ref }) }
                         , { sample | id = "Hover column", state = sample.state |> (\s -> { s | hover = Just sample.ref, hoverColumn = Just { schema = sample.ref.schema, table = sample.ref.table, column = "name" } }) }
                         , { sample | id = "Selected", state = sample.state |> (\s -> { s | selected = True }) }
                         ]
                            |> List.indexedMap (\i model -> div [ css (B.cond (i == 0) [] [ Tw.ml_6 ]) ] [ text (model.id ++ ":"), br [] [], table model ])
                        )
              )
            , ( "table settings opened", \_ -> table { sample | state = sample.state |> (\s -> { s | openedDropdown = "table-public-users-settings" }) } )
            ]
