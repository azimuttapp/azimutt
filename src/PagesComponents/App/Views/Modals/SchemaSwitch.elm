module PagesComponents.App.Views.Modals.SchemaSwitch exposing (viewFileLoader, viewSchemaSwitchModal)

import Conf exposing (conf, constants, schemaSamples)
import Dict
import FileValue exposing (hiddenInputSingle)
import FontAwesome.Icon exposing (viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, br, button, div, h5, label, li, p, small, span, text, ul)
import Html.Attributes exposing (class, for, id, style, title, type_)
import Html.Events exposing (onClick)
import Libs.Bootstrap exposing (BsColor(..), Toggle(..), bsButton, bsModal, bsToggle, bsToggleCollapse)
import Libs.Html exposing (bText, codeText, divIf, extLink)
import Libs.Html.Attributes exposing (ariaExpanded, ariaLabelledBy, role)
import Libs.String as S
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.SourceId as SourceId exposing (SourceId)
import PagesComponents.App.Models exposing (Msg(..), SourceMsg(..), Switch, TimeInfo)
import PagesComponents.App.Views.Helpers exposing (formatDate, onClickConfirm)
import Time


viewSchemaSwitchModal : TimeInfo -> Switch -> String -> List Project -> Html Msg
viewSchemaSwitchModal time switch title storedProjects =
    bsModal conf.ids.projectSwitchModal
        title
        [ viewSavedProjects time storedProjects
        , viewFileUpload switch
        , viewSampleSchemas
        , div [ class "mt-3" ] (viewGetSchemaInstructions ++ viewDataPrivacyExplanation)
        ]
        [ viewFooter ]


viewSavedProjects : TimeInfo -> List Project -> Html Msg
viewSavedProjects time storedProjects =
    divIf (List.length storedProjects > 0)
        [ class "row row-cols-1 row-cols-sm-2 row-cols-lg-3" ]
        (storedProjects
            |> List.sortBy (\s -> negate (Time.posixToMillis s.updatedAt))
            |> List.map
                (\prj ->
                    div [ class "col" ]
                        [ div [ class "card h-100" ]
                            [ div [ class "card-body" ]
                                [ h5 [ class "card-title" ] [ text prj.name ]
                                , p [ class "card-text" ]
                                    [ small [ class "text-muted" ]
                                        [ text (S.plural (Dict.size prj.layouts) "No saved layout" "1 saved layout" "saved layouts")
                                        , br [] []
                                        , text ("Updated on " ++ formatDate time prj.createdAt)
                                        ]
                                    ]
                                ]
                            , div [ class "card-footer d-flex" ]
                                [ button [ type_ "button", class "link link-secondary me-auto", title "Delete this project", bsToggle Tooltip, onClickConfirm ("You you really want to delete " ++ prj.name ++ " project ?") (DeleteProject prj) ] [ viewIcon Icon.trash ]
                                , bsButton Primary [ onClick (UseProject prj) ] [ text "Use this project" ]
                                ]
                            ]
                        ]
                )
        )


viewFileUpload : Switch -> Html Msg
viewFileUpload switch =
    div [ class "mt-3" ]
        [ viewFileLoader "drop-zone"
            Nothing
            Nothing
            (if switch.loading then
                div [ class "spinner-grow text-secondary", role "status" ] [ span [ class "visually-hidden" ] [ text "Loading..." ] ]

             else
                div [ class "title h5" ] [ text "Drop your schema here or click to browse" ]
            )
        ]


viewFileLoader : String -> Maybe ProjectId -> Maybe SourceId -> Html Msg -> Html Msg
viewFileLoader labelClass project source content =
    let
        id : String
        id =
            "file-loader-" ++ (project |> Maybe.withDefault "new") ++ "-" ++ (source |> Maybe.map SourceId.toString |> Maybe.withDefault "new")
    in
    label
        ([ for id, role "button", class labelClass ]
            ++ FileValue.onDrop
                { onOver = \head tail -> SourceMsg (FileDragOver head tail)
                , onLeave = Just { id = "file-drop", msg = SourceMsg FileDragLeave }
                , onDrop = \head _ -> SourceMsg (LoadLocalFile project source head)
                }
        )
        [ hiddenInputSingle id [ ".sql" ] (\file -> SourceMsg (LoadLocalFile project source file)), content ]


viewSampleSchemas : Html Msg
viewSampleSchemas =
    div [ class "mt-3 text-center" ]
        [ text "Or just try out with "
        , div [ class "dropdown", style "display" "inline-block" ]
            [ button [ type_ "button", class "link link-primary", id "schema-samples", bsToggle Dropdown, ariaExpanded False ] [ text "an example" ]
            , ul [ class "dropdown-menu", ariaLabelledBy "schema-samples" ]
                (schemaSamples
                    |> Dict.toList
                    |> List.sortBy (\( _, ( tables, _ ) ) -> tables)
                    |> List.map (\( name, ( tables, _ ) ) -> li [] [ button [ type_ "button", class "dropdown-item", onClick (SourceMsg (LoadSample name)) ] [ text (name ++ " (" ++ String.fromInt tables ++ " tables)") ] ])
                )
            ]
        ]


viewGetSchemaInstructions : List (Html msg)
viewGetSchemaInstructions =
    [ div [] [ button ([ class "link a text-muted" ] ++ bsToggleCollapse "get-schema-instructions") [ viewIcon Icon.angleRight, text " How to get my db schema ?" ] ]
    , div [ class "collapse", id "get-schema-instructions" ]
        [ div [ class "card card-body" ]
            [ p [ class "card-text" ]
                [ text "An "
                , bText "SQL schema"
                , text " is a SQL file with all the needed instructions to create your database, so it contains your database structure. Here are some ways to get it:"
                , ul []
                    [ li [] [ bText "Export it", text " from your database: connect to your database using your favorite client and follow the instructions to extract the schema (ex: ", extLink "https://stackoverflow.com/a/54504510/15051232" [] [ text "DBeaver" ], text ")" ]
                    , li [] [ bText "Find it", text " in your project: some frameworks like Rails store the schema in your project, so you may have it (ex: with Rails it's ", codeText "db/structure.sql", text " if you use the SQL version)" ]
                    ]
                , text "If you have no idea on what I'm talking about just before, ask to the developers working on the project or your database administrator 😇"
                ]
            ]
        ]
    ]


viewDataPrivacyExplanation : List (Html msg)
viewDataPrivacyExplanation =
    [ div [] [ button ([ class "link a text-muted" ] ++ bsToggleCollapse "data-privacy") [ viewIcon Icon.angleRight, text " What about data privacy ?" ] ]
    , div [ class "collapse", id "data-privacy" ]
        [ div [ class "card card-body" ]
            [ p [ class "card-text" ] [ text "Your application schema may be a sensitive information, but no worries with Azimutt, everything stay on your machine. In fact, there is even no server at all!" ]
            , p [ class "card-text" ] [ text "Your schema is read and ", bText "parsed in your browser", text ", and then saved with the layouts in your browser ", bText "local storage", text ". Nothing fancy ^^" ]
            ]
        ]
    ]


viewFooter : Html msg
viewFooter =
    p [ class "fw-lighter fst-italic text-muted" ]
        [ bText "Azimutt"
        , text " is "
        , extLink constants.azimuttGithub [] [ text "open source" ]
        , text ", feel free to report bugs, ask questions or request features in github issues."
        ]
