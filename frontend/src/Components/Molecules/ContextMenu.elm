module Components.Molecules.ContextMenu exposing (Action, ActionHotkey, Direction(..), ItemAction(..), MenuItem, Nested(..), SubMenuItem, SubMenuItemHotkey, btn, btnDisabled, btnHotkey, btnSubmenu, doc, header, item, itemActiveStyles, itemCurrentStyles, itemDisabledActiveStyles, itemDisabledStyles, itemStyles, link, linkHtml, menu, menuStyles, nested, nestedItem, submenuHtml)

import Components.Atoms.Kbd as Kbd
import ElmBook
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Attribute, Html, a, button, div, li, span, text, ul)
import Html.Attributes exposing (class, disabled, href, tabindex, type_)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (ariaLabelledby, ariaOrientation, css, role)
import Libs.Maybe as Maybe
import Libs.Models exposing (Link)
import Libs.Models.Hotkey as Hotkey exposing (Hotkey, hotkey)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Tailwind as Tw exposing (TwClass, batch, focus, hover)
import Svg exposing (path, svg)
import Svg.Attributes as Svg


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


type Nested msg
    = SingleItem (Html msg)
    | NestedItem Direction (Html msg) (List (Nested msg))


nested : TwClass -> List (Nested msg) -> Html msg
nested classes items =
    ul [ class ("context-menu " ++ menuStyles ++ " transition duration-150 ease-in-out origin-top " ++ classes) ]
        (items |> List.map nestedItem)


nestedItem : Nested msg -> Html msg
nestedItem i =
    case i of
        SingleItem content ->
            li [] [ content ]

        NestedItem dir content items ->
            let
                dirClasses : TwClass
                dirClasses =
                    case dir of
                        BottomRight ->
                            "origin-top-left -top-1 right-1"

                        BottomLeft ->
                            -- FIXME: "origin-top-right -top-1 right-full" right-full don't work :/
                            "origin-top-right top-full right-full"

                        TopRight ->
                            "origin-bottom-left -bottom-1 right-1"

                        TopLeft ->
                            -- FIXME: "origin-bottom-right -bottom-1 right-full" right-full don't work :/
                            "origin-bottom-right bottom-full right-full"
            in
            li [ class "relative hover:bg-gray-100" ]
                [ content
                , span [ class "absolute right-1 top-1/2 -mt-2 pointer-events-none" ] [ svg [ Svg.class "context-menu-chevron fill-current h-4 w-4 transition duration-150 ease-in-out", Svg.viewBox "0 0 20 20" ] [ path [ Svg.d "M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z" ] [] ] ]
                , ul [ class (menuStyles ++ " transition duration-150 ease-in-out " ++ dirClasses) ] (items |> List.map nestedItem)
                ]



-- ITEMS


btn : TwClass -> msg -> List (Attribute msg) -> List (Html msg) -> Html msg
btn styles message attrs content =
    button ([ type_ "button", onClick message, role "menuitem", tabindex -1, css [ "block w-full text-left", focus [ "outline-none" ], itemStyles, styles ] ] ++ attrs) content


btnHotkey : TwClass -> msg -> List (Attribute msg) -> List (Html msg) -> Platform -> List Hotkey -> Html msg
btnHotkey styles action attrs content platform hotkey =
    btn (styles ++ " flex justify-between") action attrs (content ++ (hotkey |> List.head |> Maybe.mapOrElse (\k -> [ Kbd.badge [ class "ml-3" ] (Hotkey.keys platform k) ]) []))


btnDisabled : TwClass -> List (Html msg) -> Html msg
btnDisabled styles content =
    button [ type_ "button", role "menuitem", tabindex -1, css [ "block w-full text-left", focus [ "outline-none" ], itemDisabledStyles, styles ] ] content


item : TwClass -> List (Attribute msg) -> List (Html msg) -> Html msg
item styles attrs content =
    span ([ role "menuitem", css [ "block w-full text-left", itemStyles, styles ] ] ++ attrs) content


header : TwClass -> List (Attribute msg) -> List (Html msg) -> Html msg
header styles attrs content =
    span ([ role "menuitem", css [ "block w-full px-4 py-0 text-sm border-y border-b-gray-100 border-t-gray-200 bg-gray-100 text-xs font-semibold leading-6 text-gray-900", styles ] ] ++ attrs) content


type alias MenuItem msg =
    { label : String, content : ItemAction msg }


type ItemAction msg
    = Simple (Action msg)
    | SimpleHotkey (ActionHotkey msg)
    | SubMenu (List (SubMenuItem msg)) Direction
    | SubMenuHotkey (List (SubMenuItemHotkey msg)) Direction
    | Custom (Html msg) Direction


type alias Action msg =
    { action : msg }


type alias ActionHotkey msg =
    { action : msg, platform : Platform, hotkeys : List Hotkey }


type alias SubMenuItem msg =
    { label : String, action : msg }


type alias SubMenuItemHotkey msg =
    { label : String, action : msg, platform : Platform, hotkeys : List Hotkey }


btnSubmenu : MenuItem msg -> Html msg
btnSubmenu i =
    case i.content of
        Simple { action } ->
            btn "" action [] [ text i.label ]

        SimpleHotkey { action, platform, hotkeys } ->
            btnHotkey "" action [] [ text i.label ] platform hotkeys

        SubMenu submenus dir ->
            submenuHtml dir [ text (i.label ++ " »") ] (submenus |> List.map (\submenu -> btn "" submenu.action [] [ text submenu.label ]))

        SubMenuHotkey submenus dir ->
            submenuHtml dir [ text (i.label ++ " »") ] (submenus |> List.map (\submenu -> btnHotkey "" submenu.action [] [ text submenu.label ] submenu.platform submenu.hotkeys))

        Custom html dir ->
            submenuHtml dir [ text (i.label ++ " »") ] [ html ]


link : Link -> Html msg
link l =
    linkHtml l.url [] [ text l.text ]


linkHtml : String -> List (Attribute msg) -> List (Html msg) -> Html msg
linkHtml url attrs content =
    a ([ href url, role "menuitem", tabindex -1, css [ "block", itemStyles ] ] ++ attrs) content


submenuHtml : Direction -> List (Html msg) -> List (Html msg) -> Html msg
submenuHtml dir content items =
    let
        dirClasses : TwClass
        dirClasses =
            case dir of
                BottomRight ->
                    "-top-1 left-full"

                BottomLeft ->
                    "-top-1 right-full"

                TopRight ->
                    "-bottom-1 left-full"

                TopLeft ->
                    "-bottom-1 right-full"
    in
    div [ css [ "group relative flex items-center", itemStyles ] ]
        (content
            ++ [ div [ css [ "group-hover:block hidden", dirClasses, menuStyles ] ] items
               ]
        )



-- STYLES


menuStyles : TwClass
menuStyles =
    "absolute z-max w-48 min-w-max py-1 bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5"


itemStyles : TwClass
itemStyles =
    batch [ "py-2 px-4 text-sm text-gray-700", hover [ "bg-gray-100 text-gray-900" ], Tw.disabled [ "text-gray-400" ] ]


itemCurrentStyles : TwClass
itemCurrentStyles =
    batch [ "py-2 px-4 text-sm text-gray-700 bg-gray-100", hover [ "bg-gray-200 text-gray-900" ], Tw.disabled [ "text-gray-400" ] ]


itemActiveStyles : TwClass
itemActiveStyles =
    batch [ "py-2 px-4 text-sm bg-primary-600 text-white", hover [ "bg-primary-700 text-primary-50" ] ]


itemDisabledStyles : TwClass
itemDisabledStyles =
    batch [ "py-2 px-4 text-sm text-gray-400", hover [ "bg-gray-50" ] ]


itemDisabledActiveStyles : TwClass
itemDisabledActiveStyles =
    batch [ "py-2 px-4 text-sm text-primary-400", hover [ "bg-primary-50" ] ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "ContextMenu"
        |> Chapter.renderComponentList
            [ ( "basic", div [ class "h-8" ] [ div [ class "relative" ] [ menu "basic" BottomRight 0 True (text "Any HTML here!!!") ] ] )
            , ( "buttons"
              , div [ class "h-48" ]
                    [ div [ class "relative" ]
                        [ div []
                            [ btn "" msg [] [ text "btn" ]
                            , btnHotkey "" msg [] [ text "btnHotkey" ] Platform.PC [ { hotkey | key = "/" } ]
                            , btnDisabled "" [ text "btnDisabled" ]
                            , link { url = "#", text = "link" }
                            , linkHtml "#" [] [ text "linkHtml" ]
                            ]
                            |> menu "buttons" BottomRight 0 True
                        ]
                    ]
              )
            , ( "submenu"
              , div [ class "h-56" ]
                    [ div [ class "relative" ]
                        [ div []
                            [ btnSubmenu { label = "btnSubmenu Simple", content = Simple { action = msg } }
                            , btnSubmenu { label = "btnSubmenu SimpleHotkey", content = SimpleHotkey { action = msg, platform = Platform.PC, hotkeys = [ { hotkey | key = "/" } ] } }
                            , btnSubmenu { label = "btnSubmenu SubMenu", content = SubMenu [ { label = "submenu 1", action = msg }, { label = "submenu 2", action = msg } ] BottomRight }
                            , btnSubmenu { label = "btnSubmenu SubMenuHotkey", content = SubMenuHotkey [ { label = "submenu 1", action = msg, platform = Platform.PC, hotkeys = [ { hotkey | key = "/" } ] }, { label = "submenu 2", action = msg, platform = Platform.PC, hotkeys = [ { hotkey | key = "/" } ] } ] BottomRight }
                            , btnSubmenu { label = "btnSubmenu Custom", content = Custom (text "Custom") BottomRight }
                            , submenuHtml BottomRight [ text "submenuHtml" ] [ text "items" ]
                            ]
                            |> menu "submenu" BottomRight 0 True
                        ]
                    ]
              )
            , ( "styles"
              , div [ class "h-48" ]
                    [ div [ class "relative" ]
                        [ div []
                            [ btn itemStyles msg [] [ text "itemStyles" ]
                            , btn itemCurrentStyles msg [] [ text "itemCurrentStyles" ]
                            , btn itemActiveStyles msg [] [ text "itemActiveStyles" ]
                            , btn itemDisabledStyles msg [ disabled True ] [ text "itemDisabledStyles" ]
                            , btn itemDisabledActiveStyles msg [ disabled True ] [ text "itemDisabledActiveStyles" ]
                            ]
                            |> menu "styles" BottomRight 0 True
                        ]
                    ]
              )
            , ( "nested"
              , div [ class "h-28" ]
                    [ div [ class "relative" ]
                        [ nested ""
                            [ SingleItem (btn "" (logAction "Programming") [] [ text "Programming" ])
                            , NestedItem BottomRight
                                (btn "" (logAction "Langages") [] [ text "Langages" ])
                                [ SingleItem (btn "" (logAction "Javascript") [] [ text "Javascript" ])
                                , NestedItem BottomRight
                                    (btn "" (logAction "Python") [] [ text "Python" ])
                                    [ SingleItem (btn "" (logAction "2.7") [] [ text "2.7" ])
                                    , NestedItem BottomRight
                                        (btn "" (logAction "3") [] [ text "3" ])
                                        [ SingleItem (btn "" (logAction "3.1") [] [ text "3.1" ])
                                        ]
                                    ]
                                , SingleItem (btn "" (logAction "Go") [] [ text "Go" ])
                                , SingleItem (btn "" (logAction "Rust") [] [ text "Rust" ])
                                ]
                            , SingleItem (btn "" (logAction "Testing") [] [ text "Testing" ])
                            ]
                        ]
                    ]
              )
            , ( "multi-submenu (not working)"
              , div [ class "h-20" ]
                    [ div [ class "relative" ]
                        [ div []
                            [ btnSubmenu
                                { label = "Level 1"
                                , content =
                                    Custom
                                        (div []
                                            [ btnSubmenu { label = "Level 2", content = Custom (btn "" msg [] [ text "Level 3" ]) BottomRight }
                                            , btnSubmenu { label = "Level 2.2", content = Custom (btn "" msg [] [ text "Level 3.2" ]) BottomRight }
                                            ]
                                        )
                                        BottomRight
                                }
                            , btnSubmenu
                                { label = "Level 1.1"
                                , content =
                                    Custom
                                        (div []
                                            [ btnSubmenu { label = "Level 2.1", content = Custom (btn "" msg [] [ text "Level 3.1" ]) BottomRight }
                                            ]
                                        )
                                        BottomRight
                                }
                            ]
                            |> menu "styles" BottomRight 0 True
                        ]
                    ]
              )
            ]


msg : ElmBook.Msg state
msg =
    logAction "click"
