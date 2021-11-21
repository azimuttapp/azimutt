module Components.Molecules.Dropdown exposing (Direction(..), DocState, Model, SharedDocState, doc, dropdown, initDocState)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import Dict exposing (Dict)
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, text)
import Html.Styled.Attributes exposing (css, href, id, tabindex, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Dict as D
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, role)
import Libs.Models.HtmlId exposing (HtmlId)
import Tailwind.Utilities as Tw


type alias Model =
    { id : HtmlId, direction : Direction, isOpen : Bool }


type Direction
    = BottomRight
    | BottomLeft


dropdown : Model -> (Model -> Html msg) -> (Model -> Html msg) -> Html msg
dropdown model elt content =
    let
        dropdownMenu : List Css.Style
        dropdownMenu =
            if model.isOpen then
                [ Tw.transition, Tw.ease_in, Tw.duration_75, Tw.opacity_100, Tw.transform, Tw.scale_100 ]

            else
                [ Tw.transition, Tw.ease_out, Tw.duration_100, Tw.opacity_0, Tw.transform, Tw.scale_95, Tw.pointer_events_none ]

        direction : List Css.Style
        direction =
            case model.direction of
                BottomRight ->
                    [ Tw.left_0, Tw.origin_top_left ]

                BottomLeft ->
                    [ Tw.right_0, Tw.origin_top_right ]
    in
    div [ css [ Tw.relative, Tw.inline_block, Tw.text_left ] ]
        [ elt model
        , div [ role "menu", ariaOrientation "vertical", ariaLabelledby model.id, tabindex -1, css ([ Tw.absolute, Tw.mt_2, Tw.py_1, Tw.min_w_max, Tw.rounded_md, Tw.shadow_lg, Tw.bg_white, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Css.focus [ Tw.outline_none ] ] ++ direction ++ dropdownMenu) ]
            [ content model
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dropdownDocState : DocState }


type alias DocState =
    { isOpen : Dict String Bool }


initDocState : DocState
initDocState =
    { isOpen = Dict.empty }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | dropdownDocState = s.dropdownDocState |> transform })


component : String -> (Bool -> (Bool -> Msg (SharedDocState x)) -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name buildComponent =
    ( name
    , \{ dropdownDocState } ->
        buildComponent
            (dropdownDocState.isOpen |> D.getOrElse name False)
            (\isOpen -> updateDocState (\s -> { s | isOpen = s.isOpen |> Dict.insert name isOpen }))
    )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Dropdown"
        |> Chapter.renderStatefulComponentList
            [ component "simple"
                (\isOpen setIsOpen ->
                    dropdown
                        { id = "menu-button"
                        , direction = BottomRight
                        , isOpen = isOpen
                        }
                        (\model ->
                            button [ type_ "button", id model.id, ariaExpanded True, ariaHaspopup True, onClick (setIsOpen (not isOpen)), css [ Tw.inline_flex, Tw.justify_center, Tw.w_full, Tw.rounded_md, Tw.border, Tw.border_gray_300, Tw.shadow_sm, Tw.px_4, Tw.py_2, Tw.bg_white, Tw.text_sm, Tw.font_medium, Tw.text_gray_700, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_offset_gray_100, Tw.ring_indigo_500 ], Css.hover [ Tw.bg_gray_50 ] ] ]
                                [ text "Options", Icon.solid ChevronDown [] ]
                        )
                        (\_ ->
                            div []
                                [ a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-0" ] [ text "Account settings" ]
                                , a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-1" ] [ text "Support" ]
                                , a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-2" ] [ text "License" ]
                                ]
                        )
                )
            ]
