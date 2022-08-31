module Services.SourceLogs exposing (SchemaLike, TableLike, viewContainer, viewError, viewFile, viewParsedSchema, viewResult)

import Conf
import Html exposing (Html, div, pre, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Models.Project.TableId as TableId


type alias SchemaLike x y z =
    { x | tables : List (TableLike y z) }


type alias TableLike x y =
    { x | schema : String, table : String, columns : List y }


viewContainer : List (Html msg) -> Html msg
viewContainer content =
    div [ class "mt-6 px-4 py-2 max-h-96 overflow-y-auto font-mono text-xs bg-gray-50 shadow rounded-lg" ] content


viewFile : (HtmlId -> msg) -> HtmlId -> String -> Maybe FileContent -> Html msg
viewFile toggle show filename content =
    content
        |> Maybe.mapOrElse
            (\c ->
                div []
                    [ div [ class "cursor-pointer", onClick (toggle "file") ] [ text ("Loaded " ++ filename ++ ".") ]
                    , if show == "file" then
                        div [] [ pre [ class "whitespace-pre font-mono" ] [ text c ] ]

                      else
                        div [] []
                    ]
            )
            (div [] [ div [] [ text ("Loading " ++ filename ++ ".") ] ])


viewParsedSchema : (HtmlId -> msg) -> HtmlId -> Result Decode.Error (SchemaLike x y z) -> Html msg
viewParsedSchema toggle show result =
    case result of
        Ok schema ->
            let
                count : Int
                count =
                    schema.tables |> List.length

                pad : Int -> String
                pad =
                    let
                        countLength : Int
                        countLength =
                            count |> String.fromInt |> String.length
                    in
                    \i -> i |> String.fromInt |> String.padLeft countLength ' '
            in
            div []
                [ div [ class "cursor-pointer", onClick (toggle "tables") ] [ text ("Schema built with " ++ (count |> String.pluralize "table") ++ ".") ]
                , if show == "tables" then
                    div []
                        (schema.tables
                            |> List.zipWith (\t -> ( t.schema, t.table ))
                            |> List.sortBy (\( _, id ) -> TableId.toString id)
                            |> List.indexedMap
                                (\i ( t, id ) ->
                                    div [ class "flex items-start" ]
                                        [ pre [ class "select-none" ] [ text (pad (i + 1) ++ ". ") ]
                                        , pre [ class "whitespace-pre font-mono" ] [ text (TableId.show Conf.schema.empty id ++ " (" ++ (t.columns |> String.pluralizeL "column") ++ ")") ]
                                        ]
                                )
                        )

                  else
                    div [] []
                ]

        Err err ->
            div [ class "text-red-500" ] [ text (Decode.errorToString err) ]


viewResult : Result String a -> Html msg
viewResult _ =
    div [] [ text "Done!" ]


viewError : Result String a -> Html msg
viewError result =
    case result of
        Ok _ ->
            div [] []

        Err err ->
            div [ class "text-red-500" ] [ text err ]
