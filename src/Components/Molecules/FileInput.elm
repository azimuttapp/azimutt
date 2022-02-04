module Components.Molecules.FileInput exposing (Model, basic, doc, input)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, label, p, span, text)
import Html.Attributes exposing (for)
import Libs.FileInput as FileInput exposing (File)
import Libs.Html.Attributes exposing (css, role)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind exposing (focus_ring_within_600, hover)


basic : HtmlId -> (File -> msg) -> msg -> Html msg
basic fieldId onSelect noop =
    input { id = fieldId, onDrop = \f _ -> onSelect f, onOver = Just (\_ _ -> noop), onLeave = Nothing, onSelect = onSelect }


type alias Model msg =
    { id : HtmlId
    , onDrop : File -> List File -> msg
    , onOver : Maybe (File -> List File -> msg)
    , onLeave : Maybe { id : String, msg : msg }
    , onSelect : File -> msg
    }


input : Model msg -> Html msg
input model =
    label
        ([ for model.id, role "button", css [ "flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md text-gray-600", hover [ "border-primary-400 text-primary-600" ], focus_ring_within_600 Color.primary ] ]
            ++ FileInput.onDrop { onDrop = model.onDrop, onOver = model.onOver, onLeave = model.onLeave }
        )
        [ div [ css [ "space-y-1 text-center" ] ]
            [ Icon.outline DocumentAdd "mx-auto h-12 w-12"
            , div [ css [ "flex text-sm" ] ]
                [ span [ css [ "relative cursor-pointer bg-white rounded-md font-medium text-primary-600" ] ]
                    [ span [] [ text "Upload a file" ]
                    , FileInput.hiddenInputSingle model.id [ ".sql" ] model.onSelect
                    ]
                , p [ css [ "pl-1" ] ] [ text "or drag and drop" ]
                ]
            , p [ css [ "text-xs" ] ] [ text "SQL file only" ]
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "FileInput"
        |> Chapter.renderComponentList
            [ ( "basic", basic "basic-id" (\f -> logAction ("Selected: " ++ f.name)) (logAction "Noop") )
            , ( "input"
              , input
                    { id = "input-id"
                    , onDrop = \file files -> logAction ("Drop " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", "))
                    , onOver = Just (\file files -> logAction ("Over " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", ")))
                    , onLeave = Just { id = "input-leave-id", msg = logAction "Leave" }
                    , onSelect = \file -> logAction ("Select " ++ file.name)
                    }
              )
            ]
