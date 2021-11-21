module Components.Molecules.Dropdown exposing (DocState, Model, SharedDocState, doc, initDocState, simple)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, text)
import Html.Styled.Attributes exposing (css, href, id, tabindex, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, role)
import Libs.Models.HtmlId exposing (HtmlId)
import Tailwind.Utilities as Tw


type alias Model =
    { id : HtmlId }


simple : Model -> Bool -> (Model -> Html msg) -> (Model -> List (Html msg)) -> Html msg
simple model isOpen elt content =
    div [ css [ Tw.relative, Tw.inline_block, Tw.text_left ] ]
        [ elt model
        , div [ role "menu", ariaOrientation "vertical", ariaLabelledby model.id, tabindex -1, css ([ Tw.origin_top_right, Tw.absolute, Tw.left_0, Tw.mt_2, Tw.w_56, Tw.rounded_md, Tw.shadow_lg, Tw.bg_white, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Css.focus [ Tw.outline_none ] ] ++ B.cond isOpen [] [ Tw.hidden ]) ]
            [ div [ role "none", css [ Tw.py_1 ] ] (content model)
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dropdownDocState : DocState }


type alias DocState =
    { simpleOpen : Bool }


initDocState : DocState
initDocState =
    { simpleOpen = False }


update : (DocState -> DocState) -> Msg (SharedDocState x)
update transform =
    Actions.updateState (\s -> { s | dropdownDocState = s.dropdownDocState |> transform })


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Dropdown"
        |> Chapter.renderStatefulComponentList
            [ ( "simple"
              , \{ dropdownDocState } ->
                    simple { id = "menu-button" }
                        dropdownDocState.simpleOpen
                        (\model ->
                            button [ type_ "button", id model.id, ariaExpanded True, ariaHaspopup True, onClick (update (\m -> { m | simpleOpen = not m.simpleOpen })), css [ Tw.inline_flex, Tw.justify_center, Tw.w_full, Tw.rounded_md, Tw.border, Tw.border_gray_300, Tw.shadow_sm, Tw.px_4, Tw.py_2, Tw.bg_white, Tw.text_sm, Tw.font_medium, Tw.text_gray_700, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_offset_gray_100, Tw.ring_indigo_500 ], Css.hover [ Tw.bg_gray_50 ] ] ]
                                [ text "Options"
                                , {- Heroicon name: solid/chevron-down -} Icon.view ChevronDown []
                                ]
                        )
                        (\_ ->
                            [ a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-0" ] [ text "Account settings" ]
                            , a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-1" ] [ text "Support" ]
                            , a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-2" ] [ text "License" ]
                            ]
                        )
              )
            ]
