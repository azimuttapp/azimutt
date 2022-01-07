module Services.SourceParsing.Views exposing (viewErrorAlert, viewLogs)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Conf
import DataSources.SqlParser.FileParser exposing (SchemaError)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict
import Html.Styled exposing (Html, div, p, text)
import Html.Styled.Attributes exposing (css, href)
import Libs.Html.Styled exposing (bText)
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Result as R
import Services.SourceParsing.Models exposing (ParsingState)
import Tailwind.Utilities as Tw
import Url exposing (percentEncode)


viewLogs : String -> ParsingState msg -> Html msg
viewLogs source model =
    div [ css [ Tw.mt_6, Tw.px_4, Tw.py_2, Tw.max_h_96, Tw.overflow_y_auto, Tw.font_mono, Tw.text_xs, Tw.bg_gray_50, Tw.shadow, Tw.rounded_lg ] ]
        ([ div [] [ text ("Loaded " ++ source ++ ".") ] ]
            ++ (model.lines |> M.mapOrElse (\l -> [ div [] [ text ("Found " ++ (l |> List.length |> String.fromInt) ++ " lines in the file.") ] ]) [])
            ++ (model.statements |> M.mapOrElse (\s -> [ div [] [ text ("Found " ++ (s |> Dict.size |> String.fromInt) ++ " SQL statements.") ] ]) [])
            ++ (model.commands
                    |> M.mapOrElse
                        (\commands ->
                            commands
                                |> Dict.toList
                                |> List.sortBy (\( i, _ ) -> i)
                                |> List.map (\( _, ( s, r ) ) -> r |> R.bimap (\e -> ( s, e )) (\c -> ( s, c )))
                                |> R.partition
                                |> (\( errs, cmds ) ->
                                        if (cmds |> List.length) == (model.statements |> M.mapOrElse Dict.size 0) then
                                            [ div [] [ text "All statements were correctly parsed." ] ]

                                        else if errs |> List.isEmpty then
                                            [ div [] [ text ((cmds |> List.length |> String.fromInt) ++ " statements were correctly parsed.") ] ]

                                        else
                                            (errs |> List.map (\( s, e ) -> viewParseError s e))
                                                ++ [ div [] [ text ((cmds |> List.length |> String.fromInt) ++ " statements were correctly parsed, " ++ (errs |> List.length |> String.fromInt) ++ " were in error.") ] ]
                                   )
                        )
                        []
               )
            ++ (if model.schemaErrors |> List.isEmpty then
                    []

                else
                    (model.schemaErrors |> List.map viewSchemaError) ++ [ div [] [ text ((model.schemaErrors |> List.length |> String.fromInt) ++ " statements can't be added to the schema.") ] ]
               )
            ++ (model.schema |> M.mapOrElse (\s -> [ div [] [ text ("Schema built with " ++ (s |> Dict.size |> String.fromInt) ++ " tables.") ] ]) [])
        )


viewParseError : SqlStatement -> List ParseError -> Html msg
viewParseError statement errors =
    div [ css [ Tw.text_red_500 ] ]
        (div [] [ text ("Paring error line " ++ (statement.head.line |> String.fromInt) ++ ":") ]
            :: (errors |> List.map (\error -> div [ css [ Tw.pl_3 ] ] [ text error ]))
        )


viewSchemaError : List SchemaError -> Html msg
viewSchemaError errors =
    div [ css [ Tw.text_red_500 ] ]
        (div [] [ text "Schema error:" ]
            :: (errors |> List.map (\error -> div [ css [ Tw.pl_3 ] ] [ text error ]))
        )


viewErrorAlert : ParsingState msg -> Html msg
viewErrorAlert model =
    let
        parseErrors : List (List ParseError)
        parseErrors =
            model.commands |> Maybe.map (Dict.values >> List.filterMap (\( _, r ) -> r |> R.toErrMaybe)) |> Maybe.withDefault []
    in
    if (parseErrors |> List.isEmpty) && (model.schemaErrors |> List.isEmpty) then
        div [] []

    else
        div [ css [ Tw.mt_6 ] ]
            [ Alert.withActions
                { color = Color.red
                , icon = XCircle
                , title = "Oh no! We had " ++ (((parseErrors |> List.length) + (model.schemaErrors |> List.length)) |> String.fromInt) ++ " errors."
                , actions = [ Link.light2 Color.red [ href (sendErrorReport parseErrors model.schemaErrors) ] [ text "Send error report" ] ]
                }
                [ p []
                    [ text "Parsing every SQL dialect is not a trivial task. But every error report allows to improve it. "
                    , bText "Please send it"
                    , text ", you will be able to edit it if needed to remove your private information."
                    ]
                , p [] [ text "In the meantime, you can look at the errors and your schema and try to simplify it. Or just use it as is, only not recognized statements will be missing." ]
                ]
            ]


sendErrorReport : List (List ParseError) -> List (List SchemaError) -> String
sendErrorReport parseErrors schemaErrors =
    let
        email : String
        email =
            Conf.constants.azimuttEmail

        subject : String
        subject =
            "[Azimutt] SQL Parser error report"

        body : String
        body =
            "Hi Azimutt team!\nGot some errors using the Azimutt SQL parser.\nHere are the details..."
                ++ (if parseErrors |> List.isEmpty then
                        ""

                    else
                        "\n\n\n------------------------------------------------------------- Parsing errors -------------------------------------------------------------\n\n"
                            ++ (parseErrors |> List.indexedMap (\i errors -> String.fromInt (i + 1) ++ ".\n" ++ (errors |> String.join "\n")) |> String.join "\n\n")
                   )
                ++ (if schemaErrors |> List.isEmpty then
                        ""

                    else
                        "\n\n\n------------------------------------------------------------- Schema errors -------------------------------------------------------------\n\n"
                            ++ (schemaErrors |> List.indexedMap (\i errors -> String.fromInt (i + 1) ++ ".\n" ++ (errors |> String.join "\n")) |> String.join "\n\n")
                   )
    in
    "mailto:" ++ email ++ "?subject=" ++ percentEncode subject ++ "&body=" ++ percentEncode body
