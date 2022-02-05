module PagesComponents.Projects.Id_.Views.Modals.FindPath exposing (viewFindPath)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict exposing (Dict)
import Html exposing (Html, br, button, div, h2, h3, img, input, label, option, p, pre, select, small, span, text)
import Html.Attributes exposing (alt, disabled, for, id, placeholder, selected, src, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as B
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (ariaDescribedby, css)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel
import Libs.String as String
import Libs.Tailwind exposing (focus, sm)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.FindPathDialog exposing (FindPathDialog)
import Models.Project.FindPathPath exposing (FindPathPath)
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)
import Models.Project.FindPathState as FindPathState
import Models.Project.FindPathStep exposing (FindPathStep)
import Models.Project.FindPathStepDir exposing (FindPathStepDir(..))
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), Msg(..))
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)


viewFindPath : Bool -> Dict TableId ErdTable -> FindPathSettings -> FindPathDialog -> Html Msg
viewFindPath opened tables settings model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = ModalClose (FindPathMsg FPClose)
        }
        [ viewHeader titleId
        , viewAlert
        , viewSettings model.id model.showSettings settings
        , viewSearchForm model.id tables model.from model.to
        , viewPaths model
        , viewFooter settings model
        ]


viewHeader : String -> Html msg
viewHeader titleId =
    div [ css [ "pt-6 px-6 sm:flex sm:items-start" ] ]
        [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100 sm:mx-0 sm:h-10 sm:w-10" ] ]
            [ Icon.outline LocationMarker "text-primary-600"
            ]
        , div [ css [ "mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left" ] ]
            [ h3 [ id titleId, css [ "text-lg leading-6 font-medium text-gray-900" ] ] [ text "Find a path between tables" ]
            , p [ css [ "text-sm text-gray-500" ] ]
                [ text "Use relations to find a path between two tables. Useful when you don't know how tables are connected but you want to query their data together." ]
            ]
        ]


viewAlert : Html msg
viewAlert =
    div [ css [ "px-6 mt-3" ] ]
        [ Alert.withDescription { color = Color.yellow, icon = Exclamation, title = "Experimental feature" }
            [ text "This feature is experimental to see if and how it's useful and "
            , extLink Conf.constants.azimuttDiscussionFindPath [ css [ "tw-link" ] ] [ text "gather some feedback" ]
            , text "."
            , br [] []
            , text "Please, be indulgent with the UX and share your thoughts on it (useful or not, how to improve...)."
            ]
        ]


viewSettings : HtmlId -> Bool -> FindPathSettings -> Html Msg
viewSettings modalId isOpen settings =
    div [ css [ "px-6 mt-3" ] ]
        [ button [ onClick (FindPathMsg FPToggleSettings), css [ "tw-link", focus [ "outline-none" ] ] ] [ text "Search settings" ]
        , div [ css [ "p-3 border border-gray-300 bg-gray-50 rounded-md shadow-sm", B.cond isOpen "" "hidden" ] ]
            [ p [ css [ "mt-1 text-sm text-gray-500" ] ]
                [ text """Finding all possible paths in a big graph with a lot of connections can take a long time.
                          Use the settings below to limit your search and keep the search correct.""" ]
            , viewSettingsInput (modalId ++ "-settings-ignored-tables")
                "text"
                "Ignored tables"
                "ex: users, accounts..."
                "Some columns does not have meaningful links so ignore them for better results."
                (settings.ignoredTables |> List.map TableId.show |> String.join ", ")
                (\v -> { settings | ignoredTables = v |> stringList |> List.map TableId.parse } |> FPSettingsUpdate |> FindPathMsg)
            , viewSettingsInput (modalId ++ "-settings-ignored-columns")
                "text"
                "Ignored columns"
                "ex: created_by, updated_by, owner..."
                "Some tables are big hubs which leads to bad results and performance, ignore them."
                (settings.ignoredColumns |> String.join ", ")
                (\v -> { settings | ignoredColumns = v |> stringList } |> FPSettingsUpdate |> FindPathMsg)
            , viewSettingsInput (modalId ++ "-settings-path-max-length")
                "number"
                "Max path length"
                "ex: 3"
                "Limit paths in length to limit complexity and performance."
                (String.fromInt settings.maxPathLength)
                (\v -> { settings | maxPathLength = v |> String.toInt |> Maybe.withDefault FindPathSettings.init.maxPathLength } |> FPSettingsUpdate |> FindPathMsg)
            ]
        ]


stringList : String -> List String
stringList str =
    str |> String.split "," |> List.map String.trim |> List.filter String.nonEmpty


viewSettingsInput : String -> String -> String -> String -> String -> String -> (String -> msg) -> Html msg
viewSettingsInput fieldId fieldType fieldLabel fieldPlaceholder fieldHelp fieldValue msg =
    div [ css [ "sm:grid sm:grid-cols-4 sm:gap-3 sm:items-start sm:mt-3" ] ]
        [ label [ for fieldId, css [ "block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2" ] ] [ text fieldLabel ]
        , div [ css [ "mt-1 sm:mt-0 sm:col-span-3" ] ]
            [ input [ type_ fieldType, id fieldId, value fieldValue, onInput msg, placeholder fieldPlaceholder, ariaDescribedby (fieldId ++ "-help"), css [ "w-full border-gray-300 rounded-md shadow-sm", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []
            , p [ id (fieldId ++ "-help"), css [ "text-sm text-gray-500" ] ] [ text fieldHelp ]
            ]
        ]


viewSearchForm : HtmlId -> Dict TableId ErdTable -> Maybe TableId -> Maybe TableId -> Html Msg
viewSearchForm modalId tables from to =
    div [ css [ "px-6 mt-3 flex space-x-3" ] ]
        [ viewSelectCard (modalId ++ "-from") "From" "Starting table for the path" from (FPUpdateFrom >> FindPathMsg) tables
        , viewSelectCard (modalId ++ "-to") "To" "Table you want to go to" to (FPUpdateTo >> FindPathMsg) tables
        ]


viewSelectCard : HtmlId -> String -> String -> Maybe TableId -> (Maybe TableId -> Msg) -> Dict TableId ErdTable -> Html Msg
viewSelectCard fieldId title description selectedValue buildMsg tables =
    div [ css [ "flex-grow p-3 border border-gray-300 rounded-md shadow-sm sm:col-span-3" ] ]
        [ label [ for fieldId, css [ "block text-sm font-medium text-gray-700" ] ] [ text title ]
        , div [ css [ "mt-1" ] ]
            [ select [ id fieldId, onInput (\id -> Just id |> M.filter (\i -> not (i == "")) |> Maybe.map TableId.fromString |> buildMsg), css [ "block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ]
                (option [ value "", selected (selectedValue == Nothing) ] [ text "-- Select a table" ]
                    :: (tables
                            |> Dict.values
                            |> List.map
                                (\t ->
                                    option
                                        [ value (TableId.toString t.id)
                                        , selected (selectedValue |> M.has t.id)
                                        ]
                                        [ text (TableId.show t.id) ]
                                )
                       )
                )
            ]
        , p [ css [ "mt-1 text-sm text-gray-500" ] ] [ text description ]
        ]


viewPaths : FindPathDialog -> Html Msg
viewPaths model =
    case ( model.from, model.to, model.result ) of
        ( Just from, Just to, FindPathState.Found result ) ->
            if result.paths |> List.isEmpty then
                div [ css [ "px-6 mt-3 text-center" ] ]
                    [ h2 [ css [ "mt-2 text-lg font-medium text-gray-900" ] ] [ text "No path found" ]
                    , img [ src "/assets/images/closed-door.jpg", alt "Closed door", css [ "h-96 inline-block align-middle" ] ] []
                    ]

            else
                div [ css [ "px-6 mt-3 overflow-y-auto" ] ]
                    [ div []
                        ([ text ("Found " ++ String.fromInt (List.length result.paths) ++ " paths between tables ")
                         , bText (TableId.show from)
                         , text " and "
                         , bText (TableId.show to)
                         , text ":"
                         , br [] []
                         ]
                            |> L.appendIf ((result.paths |> List.length) > 100) (small [ css [ "text-gray-500" ] ] [ text "Too much results ? Check 'Search settings' above to ignore some table or columns" ])
                        )
                    , div [ css [ "mt-3 border border-gray-300 rounded-md shadow-sm divide-y divide-gray-300" ] ]
                        (result.paths |> List.sortBy Nel.length |> List.indexedMap (viewPath result.opened from))
                    , small [ css [ "text-gray-500" ] ] [ text "Not enough results ? Check 'Search settings' above and increase max length of path or remove some ignored columns..." ]
                    , div [ css [ "mt-3" ] ]
                        [ text "We hope your like this feature. If you have a few minutes, please write us "
                        , extLink Conf.constants.azimuttDiscussionFindPath [ css [ "tw-link" ] ] [ text "a quick feedback" ]
                        , text " about it and your use case so we can continue to improve 🚀"
                        ]
                    ]

        _ ->
            div [] []


viewPath : Maybe Int -> TableId -> Int -> FindPathPath -> Html Msg
viewPath opened from i path =
    div []
        [ div [ onClick (FindPathMsg (FPToggleResult i)), css [ "px-6 py-4 cursor-pointer", B.cond (opened == Just i) "bg-primary-100 text-primary-700" "" ] ]
            (text (String.fromInt (i + 1) ++ ". ") :: span [] [ text (TableId.show from) ] :: (path |> Nel.toList |> List.concatMap viewPathStep))
        , div [ css [ "px-6 py-3 border-t border-gray-300", "text-primary-700", B.cond (opened /= Just i) "hidden" "" ] ]
            [ pre [] [ text (buildQuery from path) ]
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
    [ text " > ", span [ css [ "underline" ] ] [ text (TableId.show to.table) ] |> Tooltip.t (ColumnRef.show from ++ " " ++ dir ++ " " ++ ColumnRef.show to) ]


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


viewFooter : FindPathSettings -> FindPathDialog -> Html Msg
viewFooter settings model =
    div [ css [ "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ] ]
        (case ( model.from, model.to, model.result ) of
            ( Just from, Just to, FindPathState.Found res ) ->
                if from == res.from && to == res.to && settings == res.settings then
                    [ Button.primary3 Color.primary [ onClick (FindPathMsg FPClose) ] [ text "Done" ] ]

                else
                    [ Button.primary3 Color.primary [ onClick (FindPathMsg FPSearch) ] [ text "Search" ], span [] [ text "Results are out of sync with search 🤯" ] ]

            ( Just _, Just _, FindPathState.Searching ) ->
                [ Button.primary3 Color.primary [ disabled True ] [ Icon.loading "-ml-1 mr-2 animate-spin", text "Searching..." ] ]

            ( Just _, Just _, FindPathState.Empty ) ->
                [ Button.primary3 Color.primary [ onClick (FindPathMsg FPSearch) ] [ text "Search" ] ]

            _ ->
                [ Button.primary3 Color.primary [ disabled True ] [ text "Search" ] ]
        )
