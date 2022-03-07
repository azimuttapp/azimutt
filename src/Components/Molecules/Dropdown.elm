module Components.Molecules.Dropdown exposing (DocState, Model, SharedDocState, doc, dropdown, initDocState)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Either exposing (Either(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw


type alias Model =
    { id : HtmlId, direction : Direction, isOpen : Bool }


dropdown : Model -> (Model -> Html msg) -> (Model -> Html msg) -> Html msg
dropdown model elt content =
    div [ class "relative inline-block text-left" ]
        [ elt model
        , ContextMenu.menu model.id model.direction 2 model.isOpen (content model)
        ]



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


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Dropdown"
        |> Chapter.renderStatefulComponentList
            [ component "dropdown"
                (\opened toggleOpen ->
                    dropdown { id = "dropdown", direction = BottomRight, isOpen = opened == "dropdown" }
                        (\m -> Button.white3 Tw.primary [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "Options", Icon.solid ChevronDown "" ])
                        (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> ContextMenu.btn "" (logAction label) [ text label ])))
                )
            , component "item styles"
                (\opened toggleOpen ->
                    dropdown { id = "styles", direction = BottomRight, isOpen = opened == "styles" }
                        (\m -> Button.white3 Tw.primary [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "Options", Icon.solid ChevronDown "" ])
                        (\_ ->
                            div []
                                [ ContextMenu.btn "" (logAction "btn") [ text "btn" ]
                                , ContextMenu.btnDisabled "" [ text "btnDisabled" ]
                                , ContextMenu.link { url = "#", text = "link" }
                                , ContextMenu.btnSubmenu { label = "submenuButton Right", action = Right { action = logAction "submenuButton Right", hotkey = Nothing } }
                                , ContextMenu.btnSubmenu { label = "submenuButton Left", action = Left ([ "Item 1", "Item 2", "Item 3" ] |> List.map (\label -> { label = label, action = logAction label, hotkey = Nothing })) }
                                ]
                        )
                )
            , component "directions"
                (\opened toggleOpen ->
                    div [ class "flex space-x-3" ]
                        [ dropdown { id = "BottomRight", direction = BottomRight, isOpen = opened == "BottomRight" }
                            (\m -> Button.white3 Tw.primary [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "BottomRight", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> ContextMenu.btn "" (logAction label) [ text label ])))
                        , dropdown { id = "BottomLeft", direction = BottomLeft, isOpen = opened == "BottomLeft" }
                            (\m -> Button.white3 Tw.primary [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "BottomLeft", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> ContextMenu.btn "" (logAction label) [ text label ])))
                        , dropdown { id = "TopRight", direction = TopRight, isOpen = opened == "TopRight" }
                            (\m -> Button.white3 Tw.primary [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "TopRight", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> ContextMenu.btn "" (logAction label) [ text label ])))
                        , dropdown { id = "TopLeft", direction = TopLeft, isOpen = opened == "TopLeft" }
                            (\m -> Button.white3 Tw.primary [ id m.id, ariaExpanded True, ariaHaspopup True, onClick (toggleOpen m.id) ] [ text "TopLeft", Icon.solid ChevronDown "" ])
                            (\_ -> div [] ([ "Account settings", "Support", "License" ] |> List.map (\label -> ContextMenu.btn "" (logAction label) [ text label ])))
                        ]
                )
            ]
