module Components.Molecules.Dropdown exposing (Action, Direction(..), DocState, MenuItem, Model, SharedDocState, SubMenuItem, btn, btnDisabled, doc, dropdown, initDocState, itemDisabledStyles, itemStyles, link, menuStyles, submenuButton)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Kbd as Kbd
import Components.Atoms.Styles as Styles
import Css
import Either exposing (Either(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, text)
import Html.Styled.Attributes exposing (class, css, href, id, tabindex, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, role)
import Libs.Maybe as M
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
    | TopRight
    | TopLeft


type alias MenuItem msg =
    { label : String, action : Either (List (SubMenuItem msg)) (Action msg) }


type alias Action msg =
    { action : msg, hotkey : Maybe (List String) }


type alias SubMenuItem msg =
    { label : String, action : msg, hotkey : Maybe (List String) }


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
                    [ Tw.origin_top_left, Tw.left_0, Tw.top_full, Tw.mt_2 ]

                BottomLeft ->
                    [ Tw.origin_top_right, Tw.right_0, Tw.top_full, Tw.mt_2 ]

                TopRight ->
                    [ Tw.origin_bottom_left, Tw.left_0, Tw.bottom_full, Tw.mb_2 ]

                TopLeft ->
                    [ Tw.origin_bottom_right, Tw.right_0, Tw.bottom_full, Tw.mb_2 ]
    in
    div [ css [ Tw.relative, Tw.inline_block, Tw.text_left ] ]
        [ elt model
        , div [ role "menu", ariaOrientation "vertical", ariaLabelledby model.id, tabindex -1, css (menuStyles ++ direction ++ dropdownMenu) ]
            [ content model
            ]
        ]


link : Link -> Html msg
link l =
    a [ href l.url, role "menuitem", tabindex -1, css ([ Tw.block ] ++ itemStyles) ] [ text l.text ]


submenuButton : MenuItem msg -> Html msg
submenuButton menu =
    case menu.action of
        Left submenus ->
            div [ class "group", css ([ Tw.relative ] ++ itemStyles) ]
                [ text (menu.label ++ " »")
                , div [ class "group-hover-block", css ([ Tw.hidden, Tw.neg_top_1, Tw.left_full ] ++ menuStyles) ]
                    (submenus |> List.map (\submenu -> hotkeyBtn submenu.action submenu.label submenu.hotkey))
                ]

        Right { action, hotkey } ->
            hotkeyBtn action menu.label hotkey


hotkeyBtn : msg -> String -> Maybe (List String) -> Html msg
hotkeyBtn action label hotkey =
    btn [ Tw.flex, Tw.justify_between ] action ([ text label ] ++ (hotkey |> M.mapOrElse (\k -> [ Kbd.badge [ css [ Tw.ml_3 ] ] k ]) []))


btn : List Css.Style -> msg -> List (Html msg) -> Html msg
btn styles message content =
    button [ type_ "button", onClick message, role "menuitem", tabindex -1, css ([ Tw.block, Tw.w_full, Tw.text_left, Css.focus [ Tw.outline_none ] ] ++ itemStyles ++ styles) ] content


btnDisabled : List Css.Style -> List (Html msg) -> Html msg
btnDisabled styles content =
    button [ type_ "button", role "menuitem", tabindex -1, css ([ Tw.block, Tw.w_full, Tw.text_left, Css.focus [ Tw.outline_none ] ] ++ itemDisabledStyles ++ styles) ] content


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
    { opened : String }


initDocState : DocState
initDocState =
    { opened = "" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | dropdownDocState = s.dropdownDocState |> transform })


component : String -> (String -> (String -> Msg (SharedDocState x)) -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name buildComponent =
    ( name
    , \{ dropdownDocState } ->
        buildComponent
            dropdownDocState.opened
            (\id -> updateDocState (\s -> { s | opened = B.cond (s.opened == id) "" id }))
    )


doc : Theme -> Chapter (SharedDocState x)
doc theme =
    Chapter.chapter "Dropdown"
        |> Chapter.renderStatefulComponentList
            [ component "dropdown"
                (\opened toggleOpen ->
                    dropdown { id = "dropdown", direction = BottomRight, isOpen = opened == "dropdown" }
                        (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "Options", Icon.solid ChevronDown [] ])
                        (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn [] (logAction label) [ text label ])))
                )
            , component "item styles"
                (\opened toggleOpen ->
                    dropdown { id = "styles", direction = BottomRight, isOpen = opened == "styles" }
                        (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "Options", Icon.solid ChevronDown [] ])
                        (\_ ->
                            div []
                                [ btn [] (logAction "btn") [ text "btn" ]
                                , btnDisabled [] [ text "btnDisabled" ]
                                , link { url = "#", text = "link" }
                                , submenuButton { label = "submenuButton Right", action = Right { action = logAction "submenuButton Right", hotkey = Nothing } }
                                , submenuButton { label = "submenuButton Left", action = Left ([ "Item 1", "Item 2", "Item 3" ] |> List.map (\label -> { label = label, action = logAction label, hotkey = Nothing })) }
                                ]
                        )
                )
            , component "directions"
                (\opened toggleOpen ->
                    div [ css [ Tw.flex, Tw.space_x_3, Tw.neg_ml_3 ] ]
                        [ dropdown { id = "BottomRight", direction = BottomRight, isOpen = opened == "BottomRight" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "BottomRight", Icon.solid ChevronDown [] ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn [] (logAction label) [ text label ])))
                        , dropdown { id = "BottomLeft", direction = BottomLeft, isOpen = opened == "BottomLeft" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "BottomLeft", Icon.solid ChevronDown [] ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn [] (logAction label) [ text label ])))
                        , dropdown { id = "TopRight", direction = TopRight, isOpen = opened == "TopRight" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "TopRight", Icon.solid ChevronDown [] ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn [] (logAction label) [ text label ])))
                        , dropdown { id = "TopLeft", direction = TopLeft, isOpen = opened == "TopLeft" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "TopLeft", Icon.solid ChevronDown [] ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn [] (logAction label) [ text label ])))
                        ]
                )
            , ( "global styles", \_ -> div [] [ Styles.global, text "Global styles are needed for tooltip reveal" ] )
            ]
