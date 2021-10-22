module PagesComponents.App.Views.Navbar exposing (viewNavbar)

import Conf exposing (conf)
import Dict exposing (Dict)
import FontAwesome.Icon exposing (viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, b, button, div, form, hr, img, input, kbd, li, nav, ol, span, text, ul)
import Html.Attributes exposing (alt, attribute, autocomplete, class, height, id, placeholder, src, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Lazy exposing (lazy2)
import Libs.Bootstrap exposing (BsColor(..), Toggle(..), bsButton, bsToggle, bsToggleCollapse, bsToggleDropdown, bsToggleModal, bsToggleOffcanvas)
import Libs.Html.Attributes exposing (ariaExpanded, ariaLabel, ariaLabelledBy, track)
import Libs.List as L
import Libs.Models exposing (Text)
import Libs.Ned as Ned
import Libs.Nel as Nel exposing (Nel)
import Models.Project exposing (Column, Layout, LayoutName, Project, Schema, Table, TableId, showTableId)
import PagesComponents.App.Models exposing (FindPathMsg(..), LayoutMsg(..), Msg(..), Search, VirtualRelation, VirtualRelationMsg(..))
import Tracking exposing (events)


viewNavbar : Search -> List Project -> Maybe Project -> Maybe VirtualRelation -> Html Msg
viewNavbar search storedProjects project virtualRelation =
    nav [ id "navbar", class "navbar navbar-expand-md navbar-light bg-white shadow-sm" ]
        [ div [ class "container-fluid" ]
            [ button ([ type_ "button", class "link navbar-brand" ] ++ bsToggleOffcanvas conf.ids.menu ++ track events.openMenu) [ img [ src "/logo.png", alt "logo", height 24, class "d-inline-block align-text-top" ] [], text " Azimutt" ]
            , button ([ type_ "button", class "navbar-toggler", ariaLabel "Toggle navigation" ] ++ bsToggleCollapse "navbar-content")
                [ span [ class "navbar-toggler-icon" ] []
                ]
            , div [ class "collapse navbar-collapse", id "navbar-content" ]
                ([ lazy2 viewSearchBar (project |> Maybe.map .schema) search
                 , ul [ class "navbar-nav" ]
                    [ li [ class "nav-item" ] [ button ([ type_ "button", class "link nav-link" ] ++ bsToggleModal conf.ids.helpModal ++ track events.openHelp) [ text "?" ] ]
                    ]
                 ]
                    ++ (project
                            |> Maybe.map
                                (\p ->
                                    [ viewTitle storedProjects p
                                    , viewResetButton p.currentLayout p.schema.layout
                                    , lazy2 viewLayoutButton p.currentLayout p.layouts
                                    , div [ class "dropdown mx-3" ]
                                        [ button [ type_ "button", class "link link-secondary dropdown-toggle", id conf.ids.navFeaturesDropdown, bsToggle Dropdown, ariaExpanded False ] [ viewIcon Icon.handSparkles ]
                                        , ul [ class "dropdown-menu dropdown-menu-end", ariaLabelledBy conf.ids.navFeaturesDropdown ]
                                            [ li []
                                                [ div [ class "btn-group w-100" ]
                                                    [ button [ type_ "button", class "dropdown-item", onClick ShowAllTables ] [ text "Show all tables" ]
                                                    , button [ type_ "button", class "dropdown-item", onClick HideAllTables ] [ text "Hide all tables" ]
                                                    ]
                                                ]
                                            , li [] [ button [ type_ "button", class "dropdown-item d-flex justify-content-between", onClick (FindPathMsg (FPInit Nothing Nothing)) ] [ text "Find path between tables", kbd [ class "ms-3" ] [ text "alt + p" ] ] ]
                                            , virtualRelation
                                                |> Maybe.map (\_ -> li [] [ button [ type_ "button", class "dropdown-item", onClick (VirtualRelationMsg VRCancel) ] [ text "Cancel virtual relation" ] ])
                                                |> Maybe.withDefault
                                                    (li []
                                                        [ button
                                                            [ type_ "button"
                                                            , class "dropdown-item d-flex justify-content-between"
                                                            , title "A virtual relation is a relation which is not materialized by a foreign key"
                                                            , bsToggle Tooltip
                                                            , onClick (VirtualRelationMsg VRCreate)
                                                            ]
                                                            [ text "Create a virtual relation", kbd [ class "ms-3" ] [ text "alt + v" ] ]
                                                        ]
                                                    )
                                            , li [] [ hr [ class "dropdown-divider" ] [] ]
                                            , li [] [ button [ type_ "button", class "dropdown-item", onClick ChangeProject ] [ text "Move to project..." ] ]
                                            ]
                                        ]
                                    ]
                                )
                            |> Maybe.withDefault []
                       )
                )
            ]
        ]


viewSearchBar : Maybe Schema -> Search -> Html Msg
viewSearchBar schema search =
    schema
        |> Maybe.map
            (\s ->
                form [ class "d-flex" ]
                    [ div [ class "dropdown" ]
                        [ input ([ type_ "text", class "form-control", value search, placeholder "Search", ariaLabel "Search", autocomplete False, onInput ChangedSearch, attribute "data-bs-auto-close" "false" ] ++ bsToggleDropdown conf.ids.searchInput) []
                        , ul [ class "dropdown-menu" ]
                            (buildSuggestions s.tables s.layout search
                                |> List.map (\suggestion -> li [] [ button [ type_ "button", class "dropdown-item", onClick suggestion.msg ] suggestion.content ])
                            )
                        ]
                    ]
            )
        |> Maybe.withDefault
            (form [ class "d-flex" ]
                [ div []
                    [ input [ type_ "text", class "form-control", value search, placeholder "Search", ariaLabel "Search", autocomplete False, onInput ChangedSearch, attribute "data-bs-auto-close" "false", id conf.ids.searchInput ] []
                    , ul [ class "dropdown-menu" ] []
                    ]
                ]
            )


viewTitle : List Project -> Project -> Html Msg
viewTitle storedProjects project =
    nav [ class "mx-auto", ariaLabel "breadcrumb" ]
        [ ol [ class "breadcrumb my-auto" ]
            ([ li [ class "breadcrumb-item" ]
                [ div [ class "dropdown d-inline-block" ]
                    [ button [ type_ "button", class "link dropdown-toggle", id conf.ids.navProjectDropdown, title (String.fromInt (Dict.size project.schema.tables) ++ " tables"), bsToggle Dropdown, ariaExpanded False ] [ text project.name ]
                    , ul [ class "dropdown-menu", ariaLabelledBy conf.ids.navProjectDropdown ]
                        (intersperse (li [] [ hr [ class "dropdown-divider" ] [] ])
                            [ storedProjects
                                |> List.filter (\p -> p.name /= project.name)
                                |> List.map (\p -> li [] [ button [ type_ "button", class "dropdown-item", onClick (UseProject p) ] [ text p.name ] ])
                            , [ li [] [ button [ type_ "button", class "dropdown-item", onClick ChangeProject ] [ text "Move to project..." ] ] ]
                            ]
                        )
                    ]
                ]
             ]
                |> L.appendOn project.currentLayout
                    (\currentLayout ->
                        li [ class "breadcrumb-item" ]
                            [ div [ class "dropdown d-inline-block" ]
                                [ button [ type_ "button", class "link dropdown-toggle", id conf.ids.navLayoutDropdown, title (String.fromInt (tablesInLayout project currentLayout) ++ " tables"), bsToggle Dropdown, ariaExpanded False ] [ text currentLayout ]
                                , ul [ class "dropdown-menu", ariaLabelledBy conf.ids.navLayoutDropdown ]
                                    (intersperse (li [] [ hr [ class "dropdown-divider" ] [] ])
                                        [ project.layouts
                                            |> Dict.keys
                                            |> List.filter (\l -> l /= currentLayout)
                                            |> List.map (\l -> li [] [ button [ type_ "button", class "dropdown-item", onClick (LayoutMsg (LLoad l)) ] [ text l ] ])
                                        , [ li [] [ button [ type_ "button", class "dropdown-item", onClick (LayoutMsg LUnload) ] [ text ("Stop using " ++ currentLayout) ] ] ]
                                        ]
                                    )
                                ]
                            ]
                    )
            )
        ]


intersperse : a -> List (List a) -> List a
intersperse a list =
    List.intersperse [ a ] (list |> List.filter (\l -> l /= [])) |> List.concatMap identity


tablesInLayout : Project -> LayoutName -> Int
tablesInLayout project layout =
    project.layouts |> Dict.get layout |> Maybe.map (\l -> l.tables |> List.length) |> Maybe.withDefault 0


viewResetButton : Maybe LayoutName -> Layout -> Html Msg
viewResetButton selectedLayout layout =
    if selectedLayout /= Nothing || not ((layout.tables == []) && (layout.hiddenTables == []) && layout.canvas == { position = { left = 0, top = 0 }, zoom = 1 }) then
        bsButton Secondary [ class "me-1", onClick ResetCanvas ] [ text "Reset layout" ]

    else
        div [] []


viewLayoutButton : Maybe LayoutName -> Dict LayoutName Layout -> Html Msg
viewLayoutButton currentLayout layouts =
    if Dict.isEmpty layouts then
        bsButton Secondary ([ title "Save your current layout to reload it later" ] ++ bsToggleModal conf.ids.newLayoutModal ++ track events.openSaveLayout) [ text "Save layout" ]

    else
        div [ class "btn-group" ]
            ((currentLayout
                |> Maybe.map
                    (\layout ->
                        [ bsButton Secondary [ onClick (LayoutMsg (LUpdate layout)) ] [ text ("Update '" ++ layout ++ "'") ]
                        , bsButton Secondary [ class "dropdown-toggle dropdown-toggle-split", bsToggle Dropdown, ariaExpanded False ] [ span [ class "visually-hidden" ] [ text "Toggle Dropdown" ] ]
                        ]
                    )
                |> Maybe.withDefault [ bsButton Secondary [ class "dropdown-toggle", bsToggle Dropdown, ariaExpanded False ] [ text "Layouts" ] ]
             )
                ++ [ ul [ class "dropdown-menu dropdown-menu-end" ]
                        ([ li [] [ button ([ type_ "button", class "dropdown-item" ] ++ bsToggleModal conf.ids.newLayoutModal) [ viewIcon Icon.plus, text " Create new layout" ] ] ]
                            ++ L.prependOn currentLayout
                                (\cur -> li [] [ button [ type_ "button", class "dropdown-item", onClick (LayoutMsg LUnload) ] [ viewIcon Icon.arrowLeft, text (" Stop using " ++ cur ++ " layout") ] ])
                                (layouts
                                    |> Dict.toList
                                    |> List.sortBy (\( name, _ ) -> name)
                                    |> List.map
                                        (\( name, l ) ->
                                            li []
                                                [ button [ type_ "button", class "dropdown-item" ]
                                                    [ span [ title "Load layout", bsToggle Tooltip, onClick (LayoutMsg (LLoad name)) ] [ viewIcon Icon.upload ]
                                                    , text " "
                                                    , span [ title "Update layout with current one", bsToggle Tooltip, onClick (LayoutMsg (LUpdate name)) ] [ viewIcon Icon.edit ]
                                                    , text " "
                                                    , span [ title "Delete layout", bsToggle Tooltip, onClick (LayoutMsg (LDelete name)) ] [ viewIcon Icon.trashAlt ]
                                                    , text " "
                                                    , span [ onClick (LayoutMsg (LLoad name)) ] [ text (name ++ " (" ++ String.fromInt (List.length l.tables) ++ " tables)") ]
                                                    ]
                                                ]
                                        )
                                )
                        )
                   ]
            )


type alias Suggestion =
    { priority : Float, content : List (Html Msg), msg : Msg }


buildSuggestions : Dict TableId Table -> Layout -> Search -> List Suggestion
buildSuggestions tables layout search =
    tables |> Dict.values |> List.concatMap (asSuggestions layout search) |> List.sortBy .priority |> List.take 30


asSuggestions : Layout -> Search -> Table -> List Suggestion
asSuggestions layout search table =
    { priority = 0 - matchStrength table layout search
    , content = viewIcon Icon.angleRight :: text " " :: highlightMatch search (showTableId table.id)
    , msg = ShowTable table.id
    }
        :: (table.columns |> Ned.values |> Nel.filterMap (columnSuggestion search table))


columnSuggestion : Search -> Table -> Column -> Maybe Suggestion
columnSuggestion search table column =
    if column.name == search then
        Just
            { priority = 0 - 0.5
            , content = viewIcon Icon.angleDoubleRight :: [ text (" " ++ showTableId table.id ++ "."), b [] [ text column.name ] ]
            , msg = ShowTable table.id
            }

    else
        Nothing


highlightMatch : Search -> Text -> List (Html msg)
highlightMatch search value =
    value |> String.split search |> List.map text |> List.foldr (\i acc -> b [] [ text search ] :: i :: acc) [] |> List.drop 1


matchStrength : Table -> Layout -> Search -> Float
matchStrength table layout search =
    exactMatch search table.name
        + matchAtBeginning search table.name
        + matchNotAtBeginning search table.name
        + tableShownMalus layout table
        + columnMatchingBonus search table
        + (5 * manyColumnBonus table)
        + shortNameBonus table.name


exactMatch : Search -> Text -> Float
exactMatch search text =
    if text == search then
        3

    else
        0


matchAtBeginning : Search -> Text -> Float
matchAtBeginning search text =
    if not (search == "") && String.startsWith search text then
        2

    else
        0


matchNotAtBeginning : Search -> Text -> Float
matchNotAtBeginning search text =
    if not (search == "") && String.contains search text && not (String.startsWith search text) then
        1

    else
        0


columnMatchingBonus : Search -> Table -> Float
columnMatchingBonus search table =
    let
        columnNames : Nel Text
        columnNames =
            table.columns |> Ned.values |> Nel.map .name
    in
    if not (search == "") then
        if columnNames |> Nel.any (\columnName -> not (exactMatch search columnName == 0)) then
            0.5

        else if columnNames |> Nel.any (\columnName -> not (matchAtBeginning search columnName == 0)) then
            0.2

        else if columnNames |> Nel.any (\columnName -> not (matchNotAtBeginning search columnName == 0)) then
            0.1

        else
            0

    else
        0


shortNameBonus : Text -> Float
shortNameBonus name =
    if String.length name == 0 then
        0

    else
        1 / toFloat (String.length name)


manyColumnBonus : Table -> Float
manyColumnBonus table =
    let
        size : Int
        size =
            Ned.size table.columns
    in
    if size == 0 then
        -0.3

    else
        -1 / toFloat size


tableShownMalus : Layout -> Table -> Float
tableShownMalus layout table =
    if layout.tables |> L.memberBy .id table.id then
        -2

    else
        0
