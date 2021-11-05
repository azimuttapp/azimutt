module PagesComponents.App.Views.Modals.FindPath exposing (viewFindPathModal)

import Conf exposing (conf, constants)
import Dict exposing (Dict)
import Html exposing (Html, abbr, b, br, button, code, div, h2, input, label, option, pre, select, small, span, text)
import Html.Attributes as Attributes exposing (class, disabled, for, id, placeholder, selected, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bootstrap exposing (Toggle(..), bsDismiss, bsModal, bsParent, bsTarget, bsToggle, bsToggleCollapse)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (ariaControls, ariaDescribedby, ariaExpanded, ariaHidden, ariaLabel, ariaLabelledby, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.FindPath exposing (FindPath)
import Models.Project.FindPathPath exposing (FindPathPath)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.FindPathState exposing (FindPathState(..))
import Models.Project.FindPathStep exposing (FindPathStep)
import Models.Project.FindPathStepDir exposing (FindPathStepDir(..))
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.App.Models exposing (FindPathMsg(..), Msg(..))


viewFindPathModal : Dict TableId Table -> FindPathSettings -> FindPath -> Html Msg
viewFindPathModal tables settings model =
    bsModal conf.ids.findPathModal
        "Find path"
        ([ viewAlert ]
            ++ [ viewSettings conf.ids.findPathModal settings ]
            ++ [ viewSearchForm tables model.from model.to ]
            ++ viewPaths conf.ids.findPathModal model
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
                    [ input
                        [ type_ "text"
                        , class "form-control"
                        , id (idPrefix ++ "-settings-ignored-columns")
                        , ariaDescribedby (idPrefix ++ "-settings-ignored-columns-help")
                        , placeholder "ex: created_by, updated_by, owner..."
                        , value (settings.ignoredColumns |> String.join ", ")
                        , onInput (\v -> FindPathMsg (FPSettingsUpdate { settings | ignoredColumns = v |> String.split "," |> List.map String.trim }))
                        ]
                        []
                    , div [ class "form-text", id (idPrefix ++ "-settings-ignored-columns-help") ] [ text "Some columns does not have meaningful links so ignore them for better results." ]
                    ]
                ]
            , div [ class "row mt-3" ]
                [ label [ class "col-sm-3 col-form-label", for (idPrefix ++ "-settings-ignored-tables") ] [ text "Ignored tables" ]
                , div [ class "col-sm-9" ]
                    [ input
                        [ type_ "text"
                        , class "form-control"
                        , id (idPrefix ++ "-settings-ignored-tables")
                        , ariaDescribedby (idPrefix ++ "-settings-ignored-tables-help")
                        , placeholder "ex: users, accounts..."
                        , value (settings.ignoredTables |> List.map TableId.show |> String.join ", ")
                        , onInput (\v -> FindPathMsg (FPSettingsUpdate { settings | ignoredTables = v |> String.split "," |> List.map String.trim |> List.map TableId.parse }))
                        ]
                        []
                    , div [ class "form-text", id (idPrefix ++ "-settings-ignored-tables-help") ] [ text "Some tables are big hubs which leads to bad results and performance, ignore them." ]
                    ]
                ]
            , div [ class "row mt-3" ]
                [ label [ class "col-sm-3 col-form-label", for (idPrefix ++ "-settings-max-path-length") ] [ text "Max path length" ]
                , div [ class "col-sm-9" ]
                    [ input
                        [ type_ "number"
                        , Attributes.min "0"
                        , Attributes.max "100"
                        , class "form-control"
                        , id (idPrefix ++ "-settings-max-path-length")
                        , ariaDescribedby (idPrefix ++ "-settings-max-path-length-help")
                        , placeholder "ex: 3"
                        , value (String.fromInt settings.maxPathLength)
                        , onInput (\v -> String.toInt v |> M.mapOrElse (\l -> FindPathMsg (FPSettingsUpdate { settings | maxPathLength = l })) Noop)
                        ]
                        []
                    , div [ class "form-text", id (idPrefix ++ "-settings-max-path-length-help") ] [ text "Limit paths in length to limit complexity and performance." ]
                    ]
                ]
            ]
        ]


viewSearchForm : Dict TableId Table -> Maybe TableId -> Maybe TableId -> Html Msg
viewSearchForm tables from to =
    div [ class "row mt-3" ]
        [ div [ class "col" ] [ viewSelectCard "from" "From" "Starting table for the path" from (FPUpdateFrom >> FindPathMsg) tables ]
        , div [ class "col" ] [ viewSelectCard "to" "To" "Table you want to go to" to (FPUpdateTo >> FindPathMsg) tables ]
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
        , onInput (\id -> Just id |> M.filter (\i -> not (i == "")) |> Maybe.map TableId.fromString |> buildMsg)
        ]
        (option [ value "", selected (selectedValue == Nothing) ] [ text "-- Select a table" ]
            :: (tables
                    |> Dict.values
                    |> List.map
                        (\t ->
                            option
                                [ value (TableId.toString t.id)
                                , selected (selectedValue |> M.contains t.id)
                                ]
                                [ text (TableId.show t.id) ]
                        )
               )
        )


viewPaths : HtmlId -> FindPath -> List (Html msg)
viewPaths idPrefix model =
    case ( model.from, model.to, model.result ) of
        ( Just from, Just to, Found result ) ->
            if result.paths |> List.isEmpty then
                [ div [ class "mt-3" ] [ text "No path found" ] ]

            else
                [ div [ class "mt-3" ]
                    ([ text ("Found " ++ String.fromInt (List.length result.paths) ++ " paths between tables ")
                     , b [] [ text (TableId.show from) ]
                     , text " and "
                     , b [] [ text (TableId.show to) ]
                     , text ":"
                     , br [] []
                     ]
                        |> L.appendIf ((result.paths |> List.length) > 100)
                            (small [ class "text-muted" ] [ text "Too much results ? Check 'Search settings' above to ignore some table or columns" ])
                    )
                , div [ class "accordion mt-3", id (idPrefix ++ "-paths-accordion") ] (result.paths |> List.sortBy Nel.length |> List.indexedMap (viewPath (idPrefix ++ "-paths-accordion") from))
                , small [ class "text-muted" ] [ text "Not enough results ? Check 'Search settings' above and increase max length of path or remove some ignored columns..." ]
                , div [ class "mt-3" ]
                    [ text "We hope your like this feature. If you have a few minutes, please write us "
                    , extLink (constants.azimuttGithub ++ "/discussions/7") [] [ text "a quick feedback" ]
                    , text " about it and your use case so we can continue to improve 🚀"
                    ]
                ]

        _ ->
            []


viewPath : HtmlId -> TableId -> Int -> FindPathPath -> Html msg
viewPath accordionId from i path =
    let
        headerId : HtmlId
        headerId =
            accordionId ++ "-" ++ String.fromInt i

        collapseId : HtmlId
        collapseId =
            headerId ++ "-collapse"
    in
    div [ class "accordion-item" ]
        [ h2 [ class "accordion-header", id headerId ]
            [ button [ type_ "button", class "accordion-button collapsed", ariaControls collapseId, bsTarget collapseId, bsToggle Collapse, ariaExpanded False ]
                [ span [] (text (String.fromInt (i + 1) ++ ". ") :: span [] [ text (TableId.show from) ] :: (path |> Nel.toList |> List.concatMap viewPathStep)) ]
            ]
        , div [ class "accordion-collapse collapse", id collapseId, bsParent accordionId, ariaLabelledby headerId ]
            [ div [ class "accordion-body" ]
                [ code [] [ pre [ class "mb-0" ] [ text (buildQuery from path) ] ]
                ]
            ]
        ]


viewPathStep : FindPathStep -> List (Html msg)
viewPathStep s =
    case s.direction of
        Right ->
            viewPathStepDetails "→" s.relation.src s.relation.ref

        Left ->
            viewPathStepDetails "←" s.relation.ref s.relation.src


viewPathStepDetails : String -> ColumnRef -> ColumnRef -> List (Html msg)
viewPathStepDetails dir from to =
    [ text " > ", abbr [ title (ColumnRef.show from ++ " " ++ dir ++ " " ++ ColumnRef.show to), bsToggle Tooltip ] [ text (TableId.show to.table) ] ]


buildQuery : TableId -> FindPathPath -> String
buildQuery table joins =
    "SELECT *"
        ++ ("\nFROM " ++ TableId.show table)
        ++ (joins
                |> Nel.toList
                |> List.map
                    (\s ->
                        case s.direction of
                            Right ->
                                "\n  JOIN " ++ TableId.show s.relation.ref.table ++ " ON " ++ ColumnRef.show s.relation.ref ++ " = " ++ ColumnRef.show s.relation.src

                            Left ->
                                "\n  JOIN " ++ TableId.show s.relation.src.table ++ " ON " ++ ColumnRef.show s.relation.src ++ " = " ++ ColumnRef.show s.relation.ref
                    )
                |> String.join ""
           )


viewFooter : FindPathSettings -> FindPath -> List (Html Msg)
viewFooter settings model =
    case ( model.from, model.to, model.result ) of
        ( Just from, Just to, Found res ) ->
            if from == res.from && to == res.to && settings == res.settings then
                [ button [ type_ "button", class "btn btn-primary", bsDismiss Modal ] [ text "Done" ] ]

            else
                [ div [ class "me-auto" ] [ text "Results are out of sync with search 🤯" ], button [ type_ "button", class "btn btn-primary", onClick (FindPathMsg FPSearch) ] [ text "Search" ] ]

        ( Just _, Just _, Searching ) ->
            [ button [ type_ "button", class "btn btn-primary", disabled True ] [ span [ class "spinner-border spinner-border-sm", role "status", ariaHidden True ] [], text " Searching..." ] ]

        ( Just _, Just _, Empty ) ->
            [ button [ type_ "button", class "btn btn-primary", onClick (FindPathMsg FPSearch) ] [ text "Search" ] ]

        _ ->
            [ button [ type_ "button", class "btn btn-primary", disabled True ] [ text "Search" ] ]
