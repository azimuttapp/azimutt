module Components.Molecules.Popover exposing (DocState, SharedDocState, b, bl, br, doc, initDocState, l, r, t, tl, tr)

import Components.Atoms.Button as Button
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onMouseEnter, onMouseLeave)
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind as Tw exposing (TwClass)


t : Html msg -> Bool -> Html msg -> Html msg
t =
    popover "bottom-full mb-3 items-center"


tl : Html msg -> Bool -> Html msg -> Html msg
tl =
    popover "bottom-full mb-3 right-0 items-end"


tr : Html msg -> Bool -> Html msg -> Html msg
tr =
    popover "bottom-full mb-3 left-0"


l : Html msg -> Bool -> Html msg -> Html msg
l =
    popover "right-full mr-3 top-1/2 transform -translate-y-2/4 items-end"


r : Html msg -> Bool -> Html msg -> Html msg
r =
    popover "left-full ml-3 top-1/2 transform -translate-y-2/4"


b : Html msg -> Bool -> Html msg -> Html msg
b =
    popover "top-full mt-3 items-center"


bl : Html msg -> Bool -> Html msg -> Html msg
bl =
    popover "top-full mt-3 right-0 items-end"


br : Html msg -> Bool -> Html msg -> Html msg
br =
    popover "top-full mt-3 left-0"


popover : TwClass -> Html msg -> Bool -> Html msg -> Html msg
popover bubble content isOpen item =
    div [ class "relative inline-flex flex-col items-center w-full" ]
        [ item
        , div [ css [ "absolute flex-col z-max", bubble, B.cond isOpen "flex" "hidden" ] ]
            [ div [ class "relative leading-none" ] [ content ]
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | popoverDocState : DocState }


type alias DocState =
    { opened : String }


initDocState : DocState
initDocState =
    { opened = "" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | popoverDocState = s.popoverDocState |> transform })


open : String -> Msg (SharedDocState x)
open key =
    updateDocState (\s -> { s | opened = key })


close : Msg (SharedDocState x)
close =
    updateDocState (\s -> { s | opened = "" })


popoverContent : Html msg
popoverContent =
    div [ class "bg-white shadow-lg rounded-lg border" ]
        [ div [ class "flex flex-col p-6 text-center" ]
            [ div [ class "order-2 mt-2 text-lg leading-6 font-medium text-gray-500" ] [ text "Pepperoni" ]
            , div [ class "order-1 text-5xl font-extrabold text-indigo-600" ] [ text "100%" ]
            ]
        ]


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Popover"
        |> Chapter.renderStatefulComponentList
            [ ( "popover"
              , \{ popoverDocState } ->
                    div []
                        ([ ( "Top", t popoverContent )
                         , ( "Top left", tl popoverContent )
                         , ( "Top right", tr popoverContent )
                         , ( "Left", l popoverContent )
                         , ( "Right", r popoverContent )
                         , ( "Bottom", b popoverContent )
                         , ( "Bottom left", bl popoverContent )
                         , ( "Bottom right", br popoverContent )
                         ]
                            |> List.map
                                (\( label, buildPopover ) ->
                                    span [ class "ml-3 inline-flex flex-col items-center" ]
                                        [ Button.primary3 Tw.indigo [ onMouseEnter (open label), onMouseLeave close ] [ text label ]
                                            |> buildPopover (popoverDocState.opened == label)
                                        ]
                                )
                        )
              )
            ]
