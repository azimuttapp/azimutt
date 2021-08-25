module PagesComponents.App.Views.Modals.FindPath exposing (viewFindPathModal)

import Conf exposing (conf)
import Dict exposing (Dict)
import Html exposing (Html, b, br, button, div, input, label, li, ol, option, select, span, text)
import Html.Attributes as Attributes exposing (class, disabled, for, id, placeholder, selected, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bootstrap exposing (Toggle(..), bsDismiss, bsModal, bsToggleCollapse)
import Libs.Html.Attributes exposing (ariaDescribedBy, ariaHidden, ariaLabel, role)
import Libs.Maybe as M
import Libs.Models exposing (HtmlId)
import Libs.Nel as Nel
import Models.Project exposing (FindPath, FindPathPath, FindPathSettings, FindPathState(..), FindPathStepDir(..), Table, TableId, parseTableId, showColumnRef, showTableId, stringAsTableId, tableIdAsString)
import PagesComponents.App.Models exposing (Msg(..))


viewFindPathModal : Dict TableId Table -> FindPathSettings -> FindPath -> Html Msg
viewFindPathModal tables settings model =
    bsModal conf.ids.findPathModal
        "Find path"
        ([ viewAlert ]
            ++ [ viewSettings conf.ids.findPathModal settings ]
            ++ [ viewSearchForm tables model.from model.to ]
            ++ viewPaths model
        )
        (viewFooter settings model)


viewAlert : Html msg
viewAlert =
    div [ class "alert alert-warning alert-dismissible", role "alert" ]
        [ b [] [ text "!!! This feature is experimental !!!" ]
        , br [] []
        , text "Beware on complex graph to adjust settings to keep complexity acceptable for your browser."
        , button [ type_ "button", class "btn-close", bsDismiss Alert, ariaLabel "Close" ] []
        ]


viewSettings : HtmlId -> FindPathSettings -> Html Msg
viewSettings idPrefix settings =
    div []
        [ button ([ class "link a" ] ++ bsToggleCollapse (idPrefix ++ "-settings")) [ text "Search settings" ]
        , div [ class "collapse", id (idPrefix ++ "-settings") ]
            [ div []
                [ text
                    """Finding all possible paths in a big graph with a lot of connections can take a long time.
                       Use the settings below to limit your search and keep the search correct."""
                ]
            , div [ class "row mt-3" ]
                [ label [ class "col-sm-3 col-form-label", for (idPrefix ++ "-settings-ignored-columns") ] [ text "Ignored columns" ]
                , div [ class "col-sm-9" ]
                    [ input [ type_ "text", class "form-control", id (idPrefix ++ "-settings-ignored-columns"), ariaDescribedBy (idPrefix ++ "-settings-ignored-columns-help"), placeholder "ex: created_by, updated_by, owner...", value (settings.ignoredColumns |> String.join ", "), onInput (\v -> UpdateFindPathSettings { settings | ignoredColumns = v |> String.split "," |> List.map String.trim }) ] []
                    , div [ class "form-text", id (idPrefix ++ "-settings-ignored-columns-help") ] [ text "Some columns does not have meaningful links so ignore them for better results." ]
                    ]
                ]
            , div [ class "row mt-3" ]
                [ label [ class "col-sm-3 col-form-label", for (idPrefix ++ "-settings-ignored-tables") ] [ text "Ignored tables" ]
                , div [ class "col-sm-9" ]
                    [ input [ type_ "text", class "form-control", id (idPrefix ++ "-settings-ignored-tables"), ariaDescribedBy (idPrefix ++ "-settings-ignored-tables-help"), placeholder "ex: users, accounts...", value (settings.ignoredTables |> List.map showTableId |> String.join ", "), onInput (\v -> UpdateFindPathSettings { settings | ignoredTables = v |> String.split "," |> List.map String.trim |> List.map parseTableId }) ] []
                    , div [ class "form-text", id (idPrefix ++ "-settings-ignored-tables-help") ] [ text "Some tables are big hubs which leads to bad results and performance, ignore them." ]
                    ]
                ]
            , div [ class "row mt-3" ]
                [ label [ class "col-sm-3 col-form-label", for (idPrefix ++ "-settings-max-path-length") ] [ text "Max path length" ]
                , div [ class "col-sm-9" ]
                    [ input [ type_ "number", Attributes.min "0", Attributes.max "100", class "form-control", id (idPrefix ++ "-settings-max-path-length"), ariaDescribedBy (idPrefix ++ "-settings-max-path-length-help"), placeholder "ex: 3", value (String.fromInt settings.maxPathLength), onInput (\v -> String.toInt v |> Maybe.map (\l -> UpdateFindPathSettings { settings | maxPathLength = l }) |> Maybe.withDefault Noop) ] []
                    , div [ class "form-text", id (idPrefix ++ "-settings-max-path-length-help") ] [ text "Limit paths in length to limit complexity and performance." ]
                    ]
                ]
            ]
        ]


viewSearchForm : Dict TableId Table -> Maybe TableId -> Maybe TableId -> Html Msg
viewSearchForm tables from to =
    div [ class "row mt-3" ]
        [ div [ class "col" ] [ viewSelectCard "from" "From" "Starting table for the path" from FindPathFrom tables ]
        , div [ class "col" ] [ viewSelectCard "to" "To" "Table you want to go to" to FindPathTo tables ]
        ]


viewSelectCard : String -> String -> String -> Maybe TableId -> (Maybe TableId -> Msg) -> Dict TableId Table -> Html Msg
viewSelectCard ref title description selectedValue buildMsg tables =
    div [ class "card" ]
        [ div [ class "card-body" ]
            [ label [ for (conf.ids.findPathModal ++ "-" ++ ref), class "form-label card-title h5" ] [ text title ]
            , viewSelectInput ref selectedValue buildMsg tables
            , div [ id (conf.ids.findPathModal ++ "-" ++ ref ++ "-help"), class "form-text" ] [ text description ]
            ]
        ]


viewSelectInput : String -> Maybe TableId -> (Maybe TableId -> Msg) -> Dict TableId Table -> Html Msg
viewSelectInput ref selectedValue buildMsg tables =
    select
        [ class "form-select"
        , id (conf.ids.findPathModal ++ "-" ++ ref)
        , onInput (\id -> Just id |> M.filter (\i -> not (i == "")) |> Maybe.map stringAsTableId |> buildMsg)
        ]
        (option [ value "", selected (selectedValue == Nothing) ] [ text "-- Select a table" ]
            :: (tables
                    |> Dict.values
                    |> List.map
                        (\t ->
                            option
                                [ value (tableIdAsString t.id)
                                , selected (selectedValue |> M.contains t.id)
                                ]
                                [ text (showTableId t.id) ]
                        )
               )
        )


viewPaths : FindPath -> List (Html msg)
viewPaths model =
    case ( model.from, model.to, model.result ) of
        ( Just from, Just to, Found result ) ->
            if result.paths |> List.isEmpty then
                [ div [ class "mt-3" ] [ text "No path found" ] ]

            else
                [ div [ class "mt-3" ]
                    [ text ("Found " ++ String.fromInt (List.length result.paths) ++ " paths between tables ")
                    , b [] [ text (showTableId from) ]
                    , text " and "
                    , b [] [ text (showTableId to) ]
                    , text ":"
                    ]
                , ol [ class "list-group list-group-numbered mt-3" ] (result.paths |> List.sortBy Nel.length |> List.map (viewPath from))
                ]

        _ ->
            []


viewPath : TableId -> FindPathPath -> Html msg
viewPath from path =
    li [ class "list-group-item" ]
        (span [] [ text (showTableId from) ]
            :: (path
                    |> Nel.toList
                    |> List.concatMap
                        (\s ->
                            [ text " > "
                            , case s.direction of
                                Right ->
                                    span [ title (showColumnRef s.relation.src ++ " -> " ++ showColumnRef s.relation.ref) ] [ text (showTableId s.relation.ref.table) ]

                                Left ->
                                    span [ title (showColumnRef s.relation.ref ++ " <- " ++ showColumnRef s.relation.src) ] [ text (showTableId s.relation.src.table) ]
                            ]
                        )
               )
        )


viewFooter : FindPathSettings -> FindPath -> List (Html Msg)
viewFooter settings model =
    case ( model.from, model.to, model.result ) of
        ( Just from, Just to, Found res ) ->
            if from == res.from && to == res.to && settings == res.settings then
                [ button [ type_ "button", class "btn btn-primary", bsDismiss Modal ] [ text "Done" ] ]

            else
                [ div [ class "me-auto" ] [ text "Results are out of sync with search 🤯" ], button [ type_ "button", class "btn btn-primary", onClick FindPathSearch ] [ text "Search" ] ]

        ( Just _, Just _, Searching ) ->
            [ button [ type_ "button", class "btn btn-primary", disabled True ] [ span [ class "spinner-border spinner-border-sm", role "status", ariaHidden True ] [], text " Searching..." ] ]

        ( Just _, Just _, Empty ) ->
            [ button [ type_ "button", class "btn btn-primary", onClick FindPathSearch ] [ text "Search" ] ]

        _ ->
            [ button [ type_ "button", class "btn btn-primary", disabled True ] [ text "Search" ] ]
