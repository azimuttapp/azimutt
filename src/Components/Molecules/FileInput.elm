module Components.Molecules.FileInput exposing (Model, basic, doc, input, projectFile, schemaFile)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import FileValue exposing (File)
import Html exposing (Html, div, label, p, span, text)
import Html.Attributes exposing (for)
import Libs.Html.Attributes exposing (css, role)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw exposing (focus_ring_within_600, hover)


schemaFile : HtmlId -> (File -> msg) -> msg -> Html msg
schemaFile htmlId onSelect noop =
    input
        { id = htmlId
        , onDrop = \f _ -> onSelect f
        , onOver = \_ _ -> noop
        , onLeave = Nothing
        , onSelect = onSelect
        , content =
            div [ css [ "space-y-1 text-center" ] ]
                [ Icon.outline2x DocumentAdd "mx-auto"
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload your SQL schema" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".sql file only" ]
                ]
        , mimes = [ ".sql" ]
        }


projectFile : HtmlId -> (File -> msg) -> msg -> Html msg
projectFile htmlId onSelect noop =
    input
        { id = htmlId
        , onDrop = \f _ -> onSelect f
        , onOver = \_ _ -> noop
        , onLeave = Nothing
        , onSelect = onSelect
        , content =
            div [ css [ "space-y-1 text-center" ] ]
                [ Icon.outline2x FolderAdd "mx-auto"
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload a project file" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".azimutt.json file only" ]
                ]
        , mimes = [ ".azimutt.json" ]
        }


basic : HtmlId -> (File -> msg) -> msg -> List String -> Html msg -> Html msg
basic htmlId onSelect noop mimes content =
    input
        { id = htmlId
        , onDrop = \f _ -> onSelect f
        , onOver = \_ _ -> noop
        , onLeave = Nothing
        , onSelect = onSelect
        , content = content
        , mimes = mimes
        }


type alias Model msg =
    { id : HtmlId
    , onDrop : File -> List File -> msg
    , onOver : File -> List File -> msg
    , onLeave : Maybe { id : String, msg : msg }
    , onSelect : File -> msg
    , content : Html msg
    , mimes : List String
    }


input : Model msg -> Html msg
input model =
    label
        ([ for model.id, role "button", css [ "flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md text-gray-600", hover [ "border-primary-400 text-primary-600" ], focus_ring_within_600 Tw.primary ] ]
            ++ FileValue.onDrop { onDrop = model.onDrop, onOver = model.onOver, onLeave = model.onLeave }
        )
        [ model.content
        , FileValue.hiddenInputSingle model.id model.mimes model.onSelect
        ]



-- DOCUMENTATION


sampleContent : Html msg
sampleContent =
    div [ css [ "space-y-1 text-center" ] ]
        [ Icon.outline2x DocumentAdd "mx-auto"
        , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload a file" ], text " or drag and drop" ]
        , p [ css [ "text-xs" ] ] [ text "SQL file only" ]
        ]


doc : Chapter x
doc =
    Chapter.chapter "FileInput"
        |> Chapter.renderComponentList
            [ ( "basic", basic "basic-id" (\f -> logAction ("Selected: " ++ f.name)) (logAction "Noop") [ ".sql" ] sampleContent )
            , ( "input"
              , input
                    { id = "input-id"
                    , onDrop = \file files -> logAction ("Drop " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", "))
                    , onOver = \file files -> logAction ("Over " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", "))
                    , onLeave = Just { id = "input-leave-id", msg = logAction "Leave" }
                    , onSelect = \file -> logAction ("Select " ++ file.name)
                    , content = sampleContent
                    , mimes = [ ".sql" ]
                    }
              )
            ]
