module Components.Molecules.Dropdown exposing (Direction(..), DocState, MenuItem, Model, SharedDocState, SubMenuItem, btn, doc, dropdown, initDocState, itemDisabledStyles, itemStyles, link, menuLinks, menuStyles, submenuButton, submenuButtons)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Styles as Styles
import Css
import Dict exposing (Dict)
import Either exposing (Either(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, text)
import Html.Styled.Attributes exposing (class, css, href, id, tabindex, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Dict as D
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, role)
import Libs.Models exposing (Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw


type alias Model =
    { id : HtmlId, direction : Direction, isOpen : Bool }


type Direction
    = BottomRight
    | BottomLeft


type alias MenuItem msg =
    { label : String, action : Either (List (SubMenuItem msg)) msg }


type alias SubMenuItem msg =
    { label : String, action : msg }


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
        , div [ role "menu", ariaOrientation "vertical", ariaLabelledby model.id, tabindex -1, css ([ Tw.mt_2 ] ++ menuStyles ++ direction ++ dropdownMenu) ]
            [ content model
            ]
        ]


menuLinks : List Link -> Model -> Html msg
menuLinks links _ =
    div [] (links |> List.map link)


link : Link -> Html msg
link l =
    a [ href l.url, role "menuitem", tabindex -1, css ([ Tw.block ] ++ itemStyles) ] [ text l.text ]


submenuButtons : List (MenuItem msg) -> Model -> Html msg
submenuButtons menus _ =
    div [] (menus |> List.map submenuButton)


submenuButton : MenuItem msg -> Html msg
submenuButton menu =
    case menu.action of
        Left submenus ->
            div [ class "group", css ([ Tw.relative ] ++ itemStyles) ]
                [ text (menu.label ++ " »")
                , div [ class "group-hover-block", css ([ Tw.hidden, Tw.neg_top_1, Tw.left_full ] ++ menuStyles) ]
                    (submenus |> List.map (\submenu -> btn submenu.action submenu.label))
                ]

        Right action ->
            btn action menu.label


btn : msg -> String -> Html msg
btn message label =
    button [ type_ "button", onClick message, role "menuitem", tabindex -1, css ([ Tw.block, Tw.w_full, Tw.text_left, Css.focus [ Tw.outline_none ] ] ++ itemStyles) ] [ text label ]


menuStyles : List Css.Style
menuStyles =
    [ Tw.absolute, Tu.z_max, Tw.w_48, Tw.min_w_max, Tw.py_1, Tw.bg_white, Tw.rounded_md, Tw.shadow_lg, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5 ]


itemStyles : List Css.Style
itemStyles =
    [ Tw.py_2, Tw.px_4, Tw.text_sm, Tw.text_gray_700, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ]


itemDisabledStyles : List Css.Style
itemDisabledStyles =
    [ Tw.py_2, Tw.px_4, Tw.text_sm, Tw.text_gray_400 ]



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


doc : Theme -> Chapter (SharedDocState x)
doc theme =
    Chapter.chapter "Dropdown"
        |> Chapter.renderStatefulComponentList
            [ component "simple"
                (\isOpen setIsOpen ->
                    dropdown { id = "menu-button", direction = BottomRight, isOpen = isOpen }
                        (\model -> Button.white3 theme.color [ id model.id, ariaExpanded True, ariaHaspopup True, onClick (setIsOpen (not isOpen)) ] [ text "Options", Icon.solid ChevronDown [] ])
                        (\_ ->
                            div []
                                [ a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-0" ] [ text "Account settings" ]
                                , a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-1" ] [ text "Support" ]
                                , a [ href "#", css [ Tw.text_gray_700, Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ] ], role "menuitem", tabindex -1, id "menu-item-2" ] [ text "License" ]
                                ]
                        )
                )
            , ( "global styles", \_ -> div [] [ Styles.global, text "Global styles are needed for tooltip reveal" ] )
            ]
