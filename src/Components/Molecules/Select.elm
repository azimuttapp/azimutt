module Components.Molecules.Select exposing (DocState, Item, Model, SharedDocState, doc, indicator, initDocState)

import Components.Atoms.Icon as Icon
import Dict exposing (Dict)
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, label, li, span, text, ul)
import Html.Attributes exposing (class, id, tabindex, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaActivedescendant, ariaExpanded, ariaHaspopup, ariaHidden, ariaLabel, ariaLabelledby, css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (Color, bg_400, focus)
import Libs.Tuple as Tuple
import Services.Lenses exposing (setHighlight, setIsOpen, setValue)


type alias Model =
    { isOpen : Bool, value : String, highlight : Maybe String }


type alias Item =
    { value : String, label : String, indicatorColor : Color, indicatorLabel : String }


indicator : HtmlId -> String -> List Item -> (String -> msg) -> (Bool -> msg) -> (Maybe String -> msg) -> Model -> Html msg
indicator htmlId inputLabel values onInput onStatus onHover model =
    let
        labelId : HtmlId
        labelId =
            htmlId ++ "-label"

        optionId : Int -> HtmlId
        optionId =
            \i -> htmlId ++ "-option-" ++ String.fromInt i

        selected : Maybe ( Int, Item )
        selected =
            values |> List.indexedMap Tuple.new |> List.find (\( _, v ) -> v.value == model.value)

        visibility : String
        visibility =
            if model.isOpen then
                ""

            else
                "transition-opacity ease-out duration-300 opacity-0 pointer-events-none"
    in
    div []
        [ label [ id labelId, class "block text-sm font-medium text-gray-700" ] [ text inputLabel ]
        , div [ class "mt-1 relative" ]
            [ button
                [ type_ "button"
                , ariaHaspopup "listbox"
                , ariaLabelledby labelId
                , ariaExpanded True
                , onClick (onStatus (not model.isOpen))
                , css [ "relative w-full bg-white border border-gray-300 rounded-md shadow-sm pl-3 pr-10 py-2 text-left cursor-default sm:text-sm", focus [ "outline-none ring-1 ring-indigo-500 border-indigo-500" ] ]
                ]
                [ selected
                    |> Maybe.mapOrElse (\( _, item ) -> ( item.label, item.indicatorLabel, bg_400 item.indicatorColor )) ( "-- no selection", "No selection", "bg-white" )
                    |> (\( itemLabel, indicatorLabel, indicatorBg ) ->
                            span [ class "flex items-center" ]
                                [ span [ ariaLabel indicatorLabel, css [ indicatorBg, "flex-shrink-0 inline-block h-2 w-2 rounded-full" ] ] []
                                , span [ class "ml-3 block truncate" ] [ text itemLabel ]
                                ]
                       )
                , span [ class "absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none" ] [ Icon.solid Icon.Selector "text-gray-400" ]
                ]
            , ul
                [ tabindex -1
                , role "listbox"
                , ariaLabelledby labelId
                , ariaActivedescendant (optionId (selected |> Maybe.mapOrElse Tuple.first 0))
                , css [ visibility, "absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto sm:text-sm focus:outline-none" ]
                ]
                (items
                    |> List.indexedMap
                        (\i item ->
                            {- Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.
                               https://package.elm-lang.org/packages/leojpod/elm-keyboard-shortcut/latest
                            -}
                            li
                                [ id (optionId i)
                                , onClick (onInput item.value)
                                , role "option"
                                , onMouseEnter (onHover (Just item.value))
                                , onMouseLeave (onHover Nothing)
                                , css [ Bool.cond (model.highlight == Just item.value) "text-white bg-indigo-600" "text-gray-900", "cursor-default select-none relative py-2 pl-3 pr-9" ]
                                ]
                                [ div [ class "flex items-center" ]
                                    [ span [ ariaHidden True, css [ bg_400 item.indicatorColor, "flex-shrink-0 inline-block h-2 w-2 rounded-full" ] ] []
                                    , span [ css [ Bool.cond (item.value == model.value) "font-semibold" "font-normal", "ml-3 block truncate" ] ]
                                        [ text item.label
                                        , span [ class "sr-only" ] [ text item.indicatorLabel ]
                                        ]
                                    ]
                                , if item.value == model.value then
                                    span [ css [ Bool.cond (model.highlight == Just item.value) "text-white" "text-indigo-600", "absolute inset-y-0 right-0 flex items-center pr-4" ] ] [ Icon.solid Icon.Check "" ]

                                  else
                                    span [] []
                                ]
                        )
                )
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | selectDocState : DocState }


type alias DocState =
    { selects : Dict String Model }


initDocState : DocState
initDocState =
    { selects = Dict.empty }


items : List Item
items =
    [ { value = "Wade Cooper", label = "Wade Cooper", indicatorColor = Tw.green, indicatorLabel = "is online" }
    , { value = "Arlene Mccoy", label = "Arlene Mccoy", indicatorColor = Tw.gray, indicatorLabel = "is offline" }
    , { value = "Devon Webb", label = "Devon Webb", indicatorColor = Tw.gray, indicatorLabel = "is offline" }
    , { value = "Tom Cook", label = "Tom Cook", indicatorColor = Tw.green, indicatorLabel = "is online" }
    , { value = "Tanya Fox", label = "Tanya Fox", indicatorColor = Tw.gray, indicatorLabel = "is offline" }
    , { value = "Hellen Schmidt", label = "Hellen Schmidt", indicatorColor = Tw.green, indicatorLabel = "is online" }
    , { value = "Caroline Schultz", label = "Caroline Schultz", indicatorColor = Tw.green, indicatorLabel = "is online" }
    , { value = "Mason Heaney", label = "Mason Heaney", indicatorColor = Tw.gray, indicatorLabel = "is offline" }
    , { value = "Claudie Smitham", label = "Claudie Smitham", indicatorColor = Tw.green, indicatorLabel = "is online" }
    , { value = "Emil Schaefer", label = "Emil Schaefer", indicatorColor = Tw.gray, indicatorLabel = "is offline" }
    ]


emptyModel : Model
emptyModel =
    { isOpen = False, value = "", highlight = Nothing }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | selectDocState = s.selectDocState |> transform })


updateModel : String -> (Model -> Model) -> Msg (SharedDocState x)
updateModel name transform =
    updateDocState (\s -> { s | selects = s.selects |> Dict.update name (Maybe.withDefault emptyModel >> transform >> Just) })


component : String -> (((Model -> Model) -> Msg (SharedDocState x)) -> Model -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ selectDocState } -> render (updateModel name) (selectDocState.selects |> Dict.getOrElse name emptyModel) )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Select"
        |> Chapter.renderStatefulComponentList
            [ component "indicator" (\update -> indicator "listbox" "Assigned to" items (\v -> (setValue v >> setIsOpen False) |> update) (setIsOpen >> update) (setHighlight >> update))
            ]
