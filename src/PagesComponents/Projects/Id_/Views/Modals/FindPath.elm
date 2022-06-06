module PagesComponents.Projects.Id_.Views.Modals.FindPath exposing (viewFindPath)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict exposing (Dict)
import Html exposing (Html, br, button, div, h2, h3, img, input, label, li, p, pre, small, span, text, ul)
import Html.Attributes exposing (alt, class, disabled, for, id, placeholder, src, tabindex, title, type_, value)
import Html.Events exposing (onClick, onFocus, onInput)
import Libs.Bool as B
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (ariaControls, ariaDescribedby, ariaExpanded, css, role)
import Libs.List as List
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel
import Libs.Tailwind as Tw exposing (focus, sm)
import Models.Project.ColumnRef as ColumnRef
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), Msg(..))
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.FindPathDialog exposing (FindPathDialog)
import PagesComponents.Projects.Id_.Models.FindPathPath exposing (FindPathPath)
import PagesComponents.Projects.Id_.Models.FindPathState as FindPathState
import PagesComponents.Projects.Id_.Models.FindPathStep exposing (FindPathStep)
import PagesComponents.Projects.Id_.Models.FindPathStepDir exposing (FindPathStepDir(..))


viewFindPath : Bool -> HtmlId -> Dict TableId ErdTable -> FindPathSettings -> FindPathDialog -> Html Msg
viewFindPath opened openedDropdown tables settings model =
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
        , viewSearchForm model.id openedDropdown tables model.from model.to
        , viewPaths tables model
        , viewFooter tables settings model
        ]


viewHeader : String -> Html msg
viewHeader titleId =
    div [ css [ "pt-6 px-6", sm [ "flex items-start" ] ] ]
        [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
            [ Icon.outline LocationMarker "text-primary-600"
            ]
        , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Find a path between tables" ]
            , p [ class "text-sm text-gray-500" ]
                [ text "Use relations to find a path between two tables. Useful when you don't know how tables are connected but you want to query their data together." ]
            ]
        ]


viewAlert : Html msg
viewAlert =
    div [ class "px-6 mt-3" ]
        [ Alert.withDescription { color = Tw.yellow, icon = Exclamation, title = "Experimental feature" }
            [ text "This feature is experimental to see if and how it's useful and "
            , extLink Conf.constants.azimuttDiscussionFindPath [ class "link" ] [ text "gather some feedback" ]
            , text "."
            , br [] []
            , text "Please, be indulgent with the UX and share your thoughts on it (useful or not, how to improve...)."
            ]
        ]


viewSettings : HtmlId -> Bool -> FindPathSettings -> Html Msg
viewSettings modalId isOpen settings =
    div [ class "px-6 mt-3" ]
        [ button [ onClick (FindPathMsg FPToggleSettings), css [ "link", focus [ "outline-none" ] ] ] [ text "Search settings" ]
        , div [ css [ "p-3 border border-gray-300 bg-gray-50 rounded-md shadow-sm", B.cond isOpen "" "hidden" ] ]
            [ p [ class "mt-1 text-sm text-gray-500" ]
                [ text """Finding all possible paths in a big graph with a lot of connections can take a long time.
                          Use the settings below to limit your search and keep the search correct.""" ]
            , viewSettingsInput (modalId ++ "-settings-ignored-tables")
                "text"
                "Ignored tables"
                "ex: users, accounts..."
                "Some columns does not have meaningful links so ignore them for better results."
                settings.ignoredTables
                (\v -> { settings | ignoredTables = v } |> FPSettingsUpdate |> FindPathMsg)
            , viewSettingsInput (modalId ++ "-settings-ignored-columns")
                "text"
                "Ignored columns"
                "ex: created_by, updated_by, owner..."
                "Some tables are big hubs which leads to bad results and performance, ignore them."
                settings.ignoredColumns
                (\v -> { settings | ignoredColumns = v } |> FPSettingsUpdate |> FindPathMsg)
            , viewSettingsInput (modalId ++ "-settings-path-max-length")
                "number"
                "Max path length"
                "ex: 3"
                "Limit paths in length to limit complexity and performance."
                (String.fromInt settings.maxPathLength)
                (\v -> { settings | maxPathLength = v |> String.toInt |> Maybe.withDefault FindPathSettings.init.maxPathLength } |> FPSettingsUpdate |> FindPathMsg)
            ]
        ]


viewSettingsInput : String -> String -> String -> String -> String -> String -> (String -> msg) -> Html msg
viewSettingsInput fieldId fieldType fieldLabel fieldPlaceholder fieldHelp fieldValue msg =
    div [ css [ sm [ "grid grid-cols-4 gap-3 items-start mt-3" ] ] ]
        [ label [ for fieldId, css [ "block text-sm font-medium text-gray-700", sm [ "mt-px pt-2" ] ] ] [ text fieldLabel ]
        , div [ css [ "mt-1", sm [ "mt-0 col-span-3" ] ] ]
            [ input [ type_ fieldType, id fieldId, value fieldValue, onInput msg, placeholder fieldPlaceholder, ariaDescribedby (fieldId ++ "-help"), css [ "w-full border-gray-300 rounded-md shadow-sm", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []
            , p [ id (fieldId ++ "-help"), class "text-sm text-gray-500" ] [ text fieldHelp ]
            ]
        ]


viewSearchForm : HtmlId -> HtmlId -> Dict TableId ErdTable -> String -> String -> Html Msg
viewSearchForm modalId openedDropdown tables from to =
    div [ class "px-6 mt-3 flex space-x-3" ]
        [ viewSelectCard openedDropdown (modalId ++ "-from") "From" "Starting table for the path" from (FPUpdateFrom >> FindPathMsg) tables
        , viewSelectCard openedDropdown (modalId ++ "-to") "To" "Table you want to go to" to (FPUpdateTo >> FindPathMsg) tables
        ]


viewSelectCard : HtmlId -> HtmlId -> String -> String -> String -> (String -> Msg) -> Dict TableId ErdTable -> Html Msg
viewSelectCard openedDropdown fieldId title description selectedValue buildMsg tables =
    div [ css [ "flex-grow p-3 border border-gray-300 rounded-md shadow-sm", sm [ "col-span-3" ] ] ]
        [ label [ for fieldId, class "block text-sm font-medium text-gray-700" ] [ text title ]
        , viewInputComboboxes openedDropdown fieldId selectedValue buildMsg tables
        , p [ class "mt-1 text-sm text-gray-500" ] [ text description ]
        ]


viewInputComboboxes : HtmlId -> HtmlId -> String -> (String -> Msg) -> Dict TableId ErdTable -> Html Msg
viewInputComboboxes openedDropdown fieldId selectedValue buildMsg tables =
    let
        optionsField : HtmlId
        optionsField =
            fieldId ++ "-options"
    in
    div [ class "relative mt-1" ]
        [ input [ type_ "text", role "combobox", id fieldId, tabindex 1, value selectedValue, onFocus (DropdownOpen fieldId), onInput buildMsg, placeholder "Choose a table", ariaControls optionsField, ariaExpanded False, class "w-full rounded-md border border-gray-300 bg-white py-2 pl-3 pr-12 shadow-sm sm:text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500" ] []
        , if openedDropdown == fieldId then
            ul [ role "listbox", id optionsField, class "absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 sm:text-sm focus:outline-none" ]
                (tables
                    |> Dict.values
                    |> List.filter (\t -> t.label |> String.contains selectedValue)
                    |> List.map
                        (\table ->
                            li [ role "option", onClick (buildMsg table.label), tabindex -1, class "group relative cursor-pointer select-none py-2 pl-3 pr-9 text-gray-900 hover:text-white hover:bg-primary-600" ]
                                (if table.label == selectedValue then
                                    [ span [ class "block truncate font-semibold" ] [ text table.label ]
                                    , span [ class "absolute inset-y-0 right-0 flex items-center pr-4 text-indigo-600 group-hover:text-white" ] [ Icon.solid Check "" ]
                                    ]

                                 else
                                    [ span [ class "block truncate" ] [ text table.label ]
                                    , span [] []
                                    ]
                                )
                        )
                )

          else
            div [] []
        ]


viewPaths : Dict TableId ErdTable -> FindPathDialog -> Html Msg
viewPaths tables model =
    case ( model.from |> existingTableId tables, model.to |> existingTableId tables, model.result ) of
        ( Just from, Just to, FindPathState.Found result ) ->
            if result.paths |> List.isEmpty then
                div [ class "px-6 mt-3 text-center" ]
                    [ h2 [ class "mt-2 text-lg font-medium text-gray-900" ] [ text "No path found" ]
                    , img [ src "/assets/images/closed-door.jpg", alt "Closed door", class "h-96 inline-block align-middle" ] []
                    ]

            else
                div [ class "px-6 mt-3 overflow-y-auto" ]
                    [ div []
                        ([ text ("Found " ++ String.fromInt (List.length result.paths) ++ " paths between tables ")
                         , bText (TableId.show from)
                         , text " and "
                         , bText (TableId.show to)
                         , text ":"
                         , br [] []
                         ]
                            |> List.appendIf ((result.paths |> List.length) > 100) (small [ class "text-gray-500" ] [ text "Too much results ? Check 'Search settings' above to ignore some table or columns" ])
                        )
                    , div [ class "mt-3 border border-gray-300 rounded-md shadow-sm divide-y divide-gray-300" ]
                        (result.paths |> List.sortBy Nel.length |> List.indexedMap (viewPath result.opened from))
                    , small [ class "text-gray-500" ] [ text "Not enough results ? Check 'Search settings' above and increase max length of path or remove some ignored columns..." ]
                    , div [ class "mt-3" ]
                        [ text "We hope your like this feature. If you have a few minutes, please write us "
                        , extLink Conf.constants.azimuttDiscussionFindPath [ class "link" ] [ text "a quick feedback" ]
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


viewPathStepDetails : String -> ErdColumnRef -> ErdColumnRef -> List (Html msg)
viewPathStepDetails dir from to =
    [ text " > ", span [ class "underline" ] [ text (TableId.show to.table) ] |> Tooltip.t (ColumnRef.show from ++ " " ++ dir ++ " " ++ ColumnRef.show to) ]


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


viewFooter : Dict TableId ErdTable -> FindPathSettings -> FindPathDialog -> Html Msg
viewFooter tables settings model =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        (case ( model.from |> existingTableId tables, model.to |> existingTableId tables, model.result ) of
            ( Just from, Just to, FindPathState.Found res ) ->
                if from == res.from && to == res.to && settings == res.settings then
                    [ Button.primary3 Tw.primary [ onClick (FindPathMsg FPClose) ] [ text "Done" ] ]

                else
                    [ Button.primary3 Tw.primary [ onClick (FindPathMsg FPSearch) ] [ text "Search" ], span [] [ text "Results are out of sync with search 🤯" ] ]

            ( Just _, Just _, FindPathState.Searching ) ->
                [ Button.primary3 Tw.primary [ disabled True ] [ Icon.loading "-ml-1 mr-2 animate-spin", text "Searching..." ] ]

            ( Just _, Just _, FindPathState.Empty ) ->
                [ Button.primary3 Tw.primary [ onClick (FindPathMsg FPSearch) ] [ text "Search" ] ]

            _ ->
                [ Button.primary3 Tw.primary [ disabled True ] [ text "Search" ] ]
        )


existingTableId : Dict TableId ErdTable -> String -> Maybe TableId
existingTableId tables input =
    tables |> Dict.get (TableId.parse input) |> Maybe.map .id
