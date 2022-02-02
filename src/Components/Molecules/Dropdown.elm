module Components.Molecules.Dropdown exposing (Action, Direction(..), DocState, MenuItem, Model, SharedDocState, SubMenuItem, btn, btnDisabled, doc, dropdown, initDocState, itemDisabledStyles, itemStyles, link, menuStyles, submenuButton)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Kbd as Kbd
import Either exposing (Either(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, button, div, text)
import Html.Attributes exposing (class, href, id, tabindex, type_)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, css, role)
import Libs.Maybe as M
import Libs.Models exposing (Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind exposing (TwClass)


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
        dropdownMenu : TwClass
        dropdownMenu =
            if model.isOpen then
                "transition ease-in duration-75 opacity-100 transform scale-100"

            else
                "transition ease-out duration-100 opacity-0 transform scale-95 pointer-events-none"

        direction : TwClass
        direction =
            case model.direction of
                BottomRight ->
                    "origin-top-left left-0 top-full mt-2"

                BottomLeft ->
                    "origin-top-right right-0 top-full mt-2"

                TopRight ->
                    "origin-bottom-left left-0 bottom-full mb-2"

                TopLeft ->
                    "origin-bottom-right right-0 bottom-full mb-2"
    in
    div [ class "relative inline-block text-left" ]
        [ elt model
        , div [ role "menu", ariaOrientation "vertical", ariaLabelledby model.id, tabindex -1, css [ menuStyles, direction, dropdownMenu ] ]
            [ content model
            ]
        ]


link : Link -> Html msg
link l =
    a [ href l.url, role "menuitem", tabindex -1, css [ "block", itemStyles ] ] [ text l.text ]


submenuButton : MenuItem msg -> Html msg
submenuButton menu =
    case menu.action of
        Left submenus ->
            div [ css [ "group relative", itemStyles ] ]
                [ text (menu.label ++ " »")
                , div [ css [ "group-hover:block hidden -top-1 left-full", menuStyles ] ]
                    (submenus |> List.map (\submenu -> hotkeyBtn submenu.action submenu.label submenu.hotkey))
                ]

        Right { action, hotkey } ->
            hotkeyBtn action menu.label hotkey


hotkeyBtn : msg -> String -> Maybe (List String) -> Html msg
hotkeyBtn action label hotkey =
    btn "flex justify-between" action ([ text label ] ++ (hotkey |> M.mapOrElse (\k -> [ Kbd.badge [ class "ml-3" ] k ]) []))


btn : TwClass -> msg -> List (Html msg) -> Html msg
btn styles message content =
    button [ type_ "button", onClick message, role "menuitem", tabindex -1, css [ "block w-full text-left focus:outline-none", itemStyles, styles ] ] content


btnDisabled : TwClass -> List (Html msg) -> Html msg
btnDisabled styles content =
    button [ type_ "button", role "menuitem", tabindex -1, css [ "block w-full text-left focus:outline-none", itemDisabledStyles, styles ] ] content


menuStyles : TwClass
menuStyles =
    "absolute z-max w-48 min-w-max py-1 bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5"


itemStyles : TwClass
itemStyles =
    "py-2 px-4 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900"


itemDisabledStyles : TwClass
itemDisabledStyles =
    "py-2 px-4 text-sm text-gray-400"



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
                        (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "Options", Icon.solid ChevronDown "" ])
                        (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn "" (logAction label) [ text label ])))
                )
            , component "item styles"
                (\opened toggleOpen ->
                    dropdown { id = "styles", direction = BottomRight, isOpen = opened == "styles" }
                        (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "Options", Icon.solid ChevronDown "" ])
                        (\_ ->
                            div []
                                [ btn "" (logAction "btn") [ text "btn" ]
                                , btnDisabled "" [ text "btnDisabled" ]
                                , link { url = "#", text = "link" }
                                , submenuButton { label = "submenuButton Right", action = Right { action = logAction "submenuButton Right", hotkey = Nothing } }
                                , submenuButton { label = "submenuButton Left", action = Left ([ "Item 1", "Item 2", "Item 3" ] |> List.map (\label -> { label = label, action = logAction label, hotkey = Nothing })) }
                                ]
                        )
                )
            , component "directions"
                (\opened toggleOpen ->
                    div [ class "flex space-x-3" ]
                        [ dropdown { id = "BottomRight", direction = BottomRight, isOpen = opened == "BottomRight" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "BottomRight", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn "" (logAction label) [ text label ])))
                        , dropdown { id = "BottomLeft", direction = BottomLeft, isOpen = opened == "BottomLeft" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "BottomLeft", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn "" (logAction label) [ text label ])))
                        , dropdown { id = "TopRight", direction = TopRight, isOpen = opened == "TopRight" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "TopRight", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn "" (logAction label) [ text label ])))
                        , dropdown { id = "TopLeft", direction = TopLeft, isOpen = opened == "TopLeft" }
                            (\m -> Button.white3 theme.color [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "TopLeft", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> btn "" (logAction label) [ text label ])))
                        ]
                )
            ]
