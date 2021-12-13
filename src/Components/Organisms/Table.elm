module Components.Organisms.Table exposing (Actions, Column, ColumnRef, DocState, Model, Relation, SharedDocState, State, doc, initDocState, table)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, br, button, div, span, text)
import Html.Styled.Attributes exposing (class, css, href, id, tabindex, title, type_)
import Html.Styled.Events exposing (onClick)
import Html.Styled.Keyed as Keyed
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, role)
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor exposing (TwColorLevel(..))
import Tailwind.Utilities as Tw


type alias Model msg =
    { id : HtmlId
    , name : String
    , isView : Bool
    , columns : List Column
    , relations : List Relation
    , state : State
    , actions : Actions msg
    }


type alias Column =
    { name : String
    , kind : String
    , nullable : Bool
    , default : Maybe String
    , comment : Maybe String
    }


type alias Relation =
    { src : ColumnRef, ref : ColumnRef }


type alias ColumnRef =
    { schema : String, table : String, column : String }


type alias State =
    { color : Color, hover : Bool, selected : Bool, openedDropdown : HtmlId }


type alias Actions msg =
    { toggleSettings : HtmlId -> msg }


table : Model msg -> Html msg
table model =
    div
        [ class "table"
        , id model.id
        , css
            ([ Tw.inline_block, Tw.bg_white, Tw.shadow_md, Tw.rounded_lg ]
                ++ B.cond model.state.selected [ Tw.ring_4, Tw.ring_red_500, Color.ring model.state.color L500 ] []
            )
        ]
        [ viewHeader model
        , viewColumns model.columns
        , viewHiddenColumns
        ]


viewHeader : Model msg -> Html msg
viewHeader model =
    let
        dropdownId : HtmlId
        dropdownId =
            model.id ++ "-settings"
    in
    div [ class "header", css [ Tw.flex, Tw.items_center, Tw.justify_items_center, Tw.rounded_t_lg, Tw.border_t_8, Tw.border_indigo_500, Color.border model.state.color L500, B.cond model.state.hover (Color.bg model.state.color L50) Tw.bg_gray_50 ] ]
        [ div (B.cond model.isView [ title "This is a view", css [ Tw.italic, Tw.underline, Css.property "text-decoration-style" "dotted" ] ] []) [ text model.name ]
        , Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = model.state.openedDropdown == dropdownId }
            (\m ->
                button
                    [ type_ "button"
                    , id m.id
                    , onClick (model.actions.toggleSettings m.id)
                    , ariaExpanded m.isOpen
                    , ariaHaspopup True
                    , css [ Tw.ml_3, Tw.rounded_full, Tw.flex, Tw.text_sm, Css.focus [ Tw.outline_none ] ]
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


viewColumns : List Column -> Html msg
viewColumns columns =
    Keyed.node "div" [ class "columns" ] (columns |> List.map (\c -> ( c.name, viewColumn c )))


viewColumn : Column -> Html msg
viewColumn column =
    div [] [ text column.name ]


viewHiddenColumns : Html msg
viewHiddenColumns =
    div [] []



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


sample : Model (Msg x)
sample =
    { id = "table-public-users"
    , name = "users"
    , isView = False
    , columns =
        [ { name = "id", kind = "integer", nullable = False, default = Nothing, comment = Nothing }
        , { name = "name", kind = "character varying(120)", nullable = False, default = Nothing, comment = Nothing }
        , { name = "email", kind = "character varying(120)", nullable = False, default = Nothing, comment = Nothing }
        , { name = "organization", kind = "integer", nullable = True, default = Nothing, comment = Nothing }
        , { name = "created_at", kind = "timestamp without time zone", nullable = False, default = Nothing, comment = Nothing }
        ]
    , relations =
        [ { src = ColumnRef "public" "accounts" "user", ref = ColumnRef "public" "users" "id" }
        ]
    , state =
        { color = Color.indigo
        , hover = False
        , selected = False
        , openedDropdown = ""
        }
    , actions =
        { toggleSettings = \id -> logAction ("open " ++ id)
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
                                }
                        }
              )
            , ( "table states"
              , \_ ->
                    div [ css [ Tw.flex ] ]
                        [ div [] [ text "View:", br [] [], table { sample | id = "view", isView = True } ]
                        , div [ css [ Tw.ml_3 ] ] [ text "Hover:", br [] [], table { sample | id = "hover", state = sample.state |> (\s -> { s | hover = True }) } ]
                        , div [ css [ Tw.ml_3 ] ] [ text "Selected:", br [] [], table { sample | id = "selected", state = sample.state |> (\s -> { s | selected = True }) } ]
                        ]
              )
            , ( "table settings opened", \_ -> table { sample | state = sample.state |> (\s -> { s | openedDropdown = "table-public-users-settings" }) } )
            ]
