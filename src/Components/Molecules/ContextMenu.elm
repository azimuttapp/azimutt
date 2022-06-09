module Components.Molecules.ContextMenu exposing (Action, Direction(..), ItemAction(..), MenuItem, SubMenuItem, btn, btnDisabled, btnHotkey, btnSubmenu, itemActiveStyles, itemDisabledActiveStyles, itemDisabledStyles, itemStyles, link, linkHtml, menu, menuStyles)

import Components.Atoms.Kbd as Kbd
import Html exposing (Attribute, Html, a, button, div, text)
import Html.Attributes exposing (class, href, tabindex, type_)
import Html.Events exposing (onClick)
import Libs.Hotkey as Hotkey exposing (Hotkey)
import Libs.Html.Attributes exposing (ariaLabelledby, ariaOrientation, css, role)
import Libs.Maybe as Maybe
import Libs.Models exposing (Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass, batch, focus, hover)


type Direction
    = BottomRight
    | BottomLeft
    | TopRight
    | TopLeft


menu : HtmlId -> Direction -> Int -> Bool -> Html msg -> Html msg
menu id direction offset isOpen content =
    let
        transitionStyles : TwClass
        transitionStyles =
            if isOpen then
                "transition ease-in duration-75 opacity-100 transform scale-100"

            else
                "transition ease-out duration-100 opacity-0 transform scale-95 pointer-events-none"

        directionStyles : TwClass
        directionStyles =
            case direction of
                BottomRight ->
                    "origin-top-left left-0 top-full mt-" ++ String.fromInt offset

                BottomLeft ->
                    "origin-top-right right-0 top-full mt-" ++ String.fromInt offset

                TopRight ->
                    "origin-bottom-left left-0 bottom-full mb-" ++ String.fromInt offset

                TopLeft ->
                    "origin-bottom-right right-0 bottom-full mb-" ++ String.fromInt offset
    in
    div [ role "menu", ariaOrientation "vertical", ariaLabelledby id, tabindex -1, css [ menuStyles, directionStyles, transitionStyles ] ]
        [ content
        ]



-- ITEMS


btn : TwClass -> msg -> List (Html msg) -> Html msg
btn styles message content =
    button [ type_ "button", onClick message, role "menuitem", tabindex -1, css [ "block w-full text-left", focus [ "outline-none" ], itemStyles, styles ] ] content


btnHotkey : TwClass -> msg -> List (Html msg) -> List Hotkey -> Html msg
btnHotkey styles action content hotkey =
    btn (styles ++ " flex justify-between") action (content ++ (hotkey |> List.head |> Maybe.mapOrElse (\k -> [ Kbd.badge [ class "ml-3" ] (Hotkey.keys k) ]) []))


btnDisabled : TwClass -> List (Html msg) -> Html msg
btnDisabled styles content =
    button [ type_ "button", role "menuitem", tabindex -1, css [ "block w-full text-left", focus [ "outline-none" ], itemDisabledStyles, styles ] ] content


type alias MenuItem msg =
    { label : String, action : ItemAction msg }


type ItemAction msg
    = Simple (Action msg)
    | SubMenu (List (SubMenuItem msg))
    | Custom (Html msg)


type alias Action msg =
    { action : msg, hotkeys : List Hotkey }


type alias SubMenuItem msg =
    { label : String, action : msg, hotkeys : List Hotkey }


btnSubmenu : MenuItem msg -> Html msg
btnSubmenu item =
    case item.action of
        Simple { action, hotkeys } ->
            btnHotkey "" action [ text item.label ] hotkeys

        SubMenu submenus ->
            div [ css [ "group relative", itemStyles ] ]
                [ text (item.label ++ " »")
                , div [ css [ "group-hover:block hidden -top-1 left-full", menuStyles ] ]
                    (submenus |> List.map (\submenu -> btnHotkey "" submenu.action [ text submenu.label ] submenu.hotkeys))
                ]

        Custom html ->
            div [ css [ "group relative", itemStyles ] ]
                [ text (item.label ++ " »")
                , div [ css [ "group-hover:block hidden -top-1 left-full", menuStyles ] ] [ html ]
                ]


link : Link -> Html msg
link l =
    linkHtml l.url [] [ text l.text ]


linkHtml : String -> List (Attribute msg) -> List (Html msg) -> Html msg
linkHtml url attrs content =
    a ([ href url, role "menuitem", tabindex -1, css [ "block", itemStyles ] ] ++ attrs) content



-- STYLES


menuStyles : TwClass
menuStyles =
    "absolute z-max w-48 min-w-max py-1 bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5"


itemStyles : TwClass
itemStyles =
    batch [ "py-2 px-4 text-sm text-gray-700", hover [ "bg-gray-100 text-gray-900" ] ]


itemActiveStyles : TwClass
itemActiveStyles =
    batch [ "py-2 px-4 text-sm bg-primary-600 text-white", hover [ "bg-primary-700 text-primary-50" ] ]


itemDisabledStyles : TwClass
itemDisabledStyles =
    batch [ "py-2 px-4 text-sm text-gray-400", hover [ "bg-gray-50" ] ]


itemDisabledActiveStyles : TwClass
itemDisabledActiveStyles =
    batch [ "py-2 px-4 text-sm text-primary-400", hover [ "bg-primary-50" ] ]
