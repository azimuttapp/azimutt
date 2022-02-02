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
import Libs.Models.Theme exposing (Theme)
import Libs.String as String
import Libs.Tailwind exposing (border_400, focusWithinRing, hover, text_600)


basic : Theme -> HtmlId -> (File -> msg) -> msg -> Html msg
basic theme fieldId onSelect noop =
    input theme { id = fieldId, onDrop = \f _ -> onSelect f, onOver = Just (\_ _ -> noop), onLeave = Nothing, onSelect = onSelect }


type alias Model msg =
    { id : HtmlId
    , onDrop : File -> List File -> msg
    , onOver : Maybe (File -> List File -> msg)
    , onLeave : Maybe { id : String, msg : msg }
    , onSelect : File -> msg
    }


input : Theme -> Model msg -> Html msg
input theme model =
    label
        ([ for model.id, role "button", css [ "flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md text-gray-600", hover (border_400 theme.color ++ " " ++ text_600 theme.color), focusWithinRing ( theme.color, 600 ) ( Color.white, 600 ) ] ]
            ++ FileInput.onDrop { onDrop = model.onDrop, onOver = model.onOver, onLeave = model.onLeave }
        )
        [ div [ css [ "space-y-1 text-center" ] ]
            [ Icon.outline DocumentAdd "mx_auto h-12 w-12"
            , div [ css [ "flex text-sm" ] ]
                [ span [ css [ "relative cursor-pointer bg-white rounded-md font-medium", text_600 theme.color ] ]
                    [ span [] [ text "Upload a file" ]
                    , FileInput.hiddenInputSingle model.id [ ".sql" ] model.onSelect
                    ]
                , p [ css [ "pl-1" ] ] [ text "or drag and drop" ]
                ]
            , p [ css [ "text-xs" ] ] [ text "SQL file only" ]
            ]
        ]



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    Chapter.chapter "FileInput"
        |> Chapter.renderComponentList
            [ ( "basic", basic theme "basic-id" (\f -> logAction ("Selected: " ++ f.name)) (logAction "Noop") )
            , ( "input"
              , input theme
                    { id = "input-id"
                    , onDrop = \file files -> logAction ("Drop " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", "))
                    , onOver = Just (\file files -> logAction ("Over " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", ")))
                    , onLeave = Just { id = "input-leave-id", msg = logAction "Leave" }
                    , onSelect = \file -> logAction ("Select " ++ file.name)
                    }
              )
            ]
