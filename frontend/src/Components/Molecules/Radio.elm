module Components.Molecules.Radio exposing (DocState, Link, RadioOption, SharedDocState, SmallCardsModel, doc, docInit, smallCards)

import ElmBook
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, div, fieldset, h2, input, label, legend, span, text)
import Html.Attributes exposing (checked, class, classList, disabled, href, id, name, type_, value)
import Html.Events exposing (onInput)
import Libs.Html.Attributes exposing (ariaLabelledby, css)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass)
import Services.Lenses exposing (setValue)


type alias SmallCardsModel a =
    { name : HtmlId, label : String, legend : String, options : List (RadioOption a), value : Maybe a, link : Maybe Link }


type alias RadioOption a =
    { value : a, text : String, disabled : Bool }


type alias Link =
    { url : String, text : String }


smallCards : (RadioOption a -> msg) -> SmallCardsModel a -> Html msg
smallCards onSelect model =
    div []
        [ div [ class "flex items-center justify-between" ]
            ([ h2 [ class "text-sm font-medium leading-6 text-gray-900" ] [ text model.label ]
             ]
                ++ (model.link |> Maybe.toList |> List.map (\link -> a [ href link.url, class "text-sm font-medium leading-6 text-indigo-600 hover:text-indigo-500" ] [ text link.text ]))
            )
        , fieldset [ class "mt-1" ]
            [ legend [ class "sr-only" ] [ text model.legend ]
            , div [ class "grid grid-cols-3 gap-3 sm:grid-cols-6" ]
                (model.options
                    |> List.indexedMap
                        (\i option ->
                            let
                                optionId : HtmlId
                                optionId =
                                    model.name ++ "-option-" ++ String.fromInt i ++ "-label"

                                isChecked : Bool
                                isChecked =
                                    model.value |> Maybe.has option.value

                                statusClass : TwClass
                                statusClass =
                                    if isChecked then
                                        "bg-indigo-600 text-white hover:bg-indigo-500"

                                    else
                                        "ring-1 ring-inset ring-gray-300 bg-white text-gray-900 hover:bg-gray-50"
                            in
                            label [ css [ "flex items-center justify-center rounded-md py-2 px-3 text-sm font-semibold sm:flex-1", statusClass ], classList [ ( "cursor-not-allowed opacity-25", option.disabled ), ( "cursor-pointer focus:outline-none", not option.disabled ) ] ]
                                [ input [ type_ "radio", name model.name, value option.text, onInput (\_ -> onSelect option), checked isChecked, disabled option.disabled, class "sr-only", ariaLabelledby optionId ] []
                                , span [ id optionId ] [ text option.text ]
                                ]
                        )
                )
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | radioDocState : DocState }


type alias DocState =
    { smallCards : SmallCardsModel Int }


docInit : DocState
docInit =
    { smallCards =
        { name = "memory"
        , label = "RAM"
        , legend = "Choose a memory option"
        , options =
            [ { value = 4, text = "4 GB", disabled = False }
            , { value = 8, text = "8 GB", disabled = False }
            , { value = 16, text = "16 GB", disabled = False }
            , { value = 32, text = "32 GB", disabled = False }
            , { value = 64, text = "64 GB", disabled = False }
            , { value = 128, text = "128 GB", disabled = True }
            ]
        , value = Just 8
        , link = Just { url = "#", text = "See performance specs" }
        }
    }


component : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ radioDocState } -> render radioDocState )


updateDocState : (DocState -> DocState) -> ElmBook.Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | radioDocState = s.radioDocState |> transform })


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Radio"
        |> Chapter.renderStatefulComponentList
            [ component "exportDialog" (\model -> smallCards (\o -> updateDocState (\s -> { s | smallCards = s.smallCards |> setValue (Just o.value) })) model.smallCards)
            ]
