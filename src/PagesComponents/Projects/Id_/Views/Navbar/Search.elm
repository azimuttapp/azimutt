module PagesComponents.Projects.Id_.Views.Navbar.Search exposing (viewNavbarSearch)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Conf
import Dict exposing (Dict)
import Html exposing (Attribute, Html, button, div, input, kbd, label, span, text)
import Html.Attributes exposing (autocomplete, class, for, id, name, placeholder, tabindex, type_, value)
import Html.Events exposing (onBlur, onFocus, onInput, onMouseDown)
import Libs.Bool as B
import Libs.Html.Attributes exposing (css, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Tailwind exposing (TwClass, focus, lg, sm)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), SearchModel)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)


viewNavbarSearch : SearchModel -> Dict TableId ErdTable -> List ErdRelation -> List TableId -> HtmlId -> HtmlId -> Html Msg
viewNavbarSearch search tables relations shownTables htmlId openedDropdown =
    div [ class "ml-6" ]
        [ div [ css [ "max-w-lg w-full", lg [ "max-w-xs" ] ] ]
            [ label [ for htmlId, class "sr-only" ] [ text "Search" ]
            , Dropdown.dropdown { id = htmlId, direction = BottomRight, isOpen = openedDropdown == htmlId }
                (\m ->
                    div []
                        [ div [ class "pointer-events-none absolute inset-y-0 left-0 pl-3 flex items-center" ] [ Icon.solid Search "text-primary-200" ]
                        , input
                            [ type_ "search"
                            , name "search"
                            , id m.id
                            , placeholder "Search"
                            , autocomplete False
                            , value search.text
                            , onInput SearchUpdated
                            , onFocus (DropdownToggle m.id)
                            , onBlur (DropdownToggle m.id)
                            , css [ "block w-full pl-10 pr-3 py-2 border border-transparent rounded-md leading-5 bg-primary-500 text-primary-100 placeholder-primary-200", focus [ "outline-none bg-white border-white ring-white text-primary-900 placeholder-primary-400" ], sm [ "text-sm" ] ]
                            ]
                            []
                        , Conf.hotkeys
                            |> Dict.get "search-open"
                            |> Maybe.andThen List.head
                            |> M.mapOrElse
                                (\h ->
                                    div [ class "absolute inset-y-0 right-0 flex py-1.5 pr-1.5" ]
                                        [ kbd [ class "inline-flex items-center border border-primary-300 rounded px-2 text-sm font-sans font-medium text-primary-300" ]
                                            [ text h.key ]
                                        ]
                                )
                                (div [] [])
                        ]
                )
                (\m ->
                    if search.text == "" then
                        div []
                            [ span [ role "menuitem", tabindex -1, css [ "flex w-full items-center", Dropdown.itemDisabledStyles ] ]
                                [ text "Type to search into tables (", Icon.solid Icon.Table "", text "), columns (", Icon.solid Tag "", text ") and relations (", Icon.solid ExternalLink "", text ")" ]
                            ]

                    else
                        performSearch tables relations search.text
                            |> (\results ->
                                    if results |> List.isEmpty then
                                        div []
                                            [ span [ role "menuitem", tabindex -1, css [ "flex w-full items-center", Dropdown.itemDisabledStyles ] ]
                                                [ text "No result :(" ]
                                            ]

                                    else
                                        div [ class "max-h-192 overflow-y-auto" ]
                                            (results |> List.indexedMap (viewSearchResult m.id shownTables (search.active |> modBy (results |> List.length))))
                               )
                )
            ]
        ]


type SearchResult
    = FoundTable ErdTable
    | FoundColumn ErdTable ErdColumn
    | FoundRelation ErdRelation


viewSearchResult : HtmlId -> List TableId -> Int -> Int -> SearchResult -> Html Msg
viewSearchResult searchId shownTables active index res =
    let
        viewItem : msg -> Icon -> List (Html msg) -> Bool -> Html msg
        viewItem =
            \msg icon content disabled ->
                let
                    commonAttrs : List (Attribute msg)
                    commonAttrs =
                        [ role "menuitem", tabindex -1 ] ++ B.cond (active == index) [ id (searchId ++ "-active") ] []

                    commonStyles : TwClass
                    commonStyles =
                        "flex w-full items-center"
                in
                if disabled then
                    span (commonAttrs ++ [ css [ commonStyles, B.cond (active == index) Dropdown.itemDisabledActiveStyles Dropdown.itemDisabledStyles ] ])
                        ([ Icon.solid icon "mr-3" ] ++ content)

                else
                    button (commonAttrs ++ [ type_ "button", onMouseDown msg, css [ commonStyles, focus [ "outline-none" ], B.cond (active == index) Dropdown.itemActiveStyles Dropdown.itemStyles ] ])
                        ([ Icon.solid icon "mr-3" ] ++ content)
    in
    case res of
        FoundTable table ->
            viewItem (ShowTable table.id) Icon.Table [ text (TableId.show table.id) ] (shownTables |> L.has table.id)

        FoundColumn table column ->
            viewItem (ShowTable table.id) Tag [ span [ class "opacity-50" ] [ text (TableId.show table.id ++ ".") ], text column.name ] (shownTables |> L.has table.id)

        FoundRelation relation ->
            if shownTables |> L.hasNot relation.src.table then
                viewItem (ShowTable relation.src.table) ExternalLink [ text relation.name ] False

            else if shownTables |> L.hasNot relation.ref.table then
                viewItem (ShowTable relation.ref.table) ExternalLink [ text relation.name ] False

            else
                viewItem (ShowTable relation.src.table) ExternalLink [ text relation.name ] True


performSearch : Dict TableId ErdTable -> List ErdRelation -> String -> List SearchResult
performSearch tables relations query =
    let
        maxResults : Int
        maxResults =
            30

        tableResults : List ( Float, SearchResult )
        tableResults =
            tables |> Dict.values |> List.filterMap (tableMatch query)

        columnResults : List ( Float, SearchResult )
        columnResults =
            if (tableResults |> List.length) < maxResults then
                tables |> Dict.values |> List.concatMap (\table -> table.columns |> Ned.values |> Nel.filterMap (columnMatch query table))

            else
                []

        relationResults : List ( Float, SearchResult )
        relationResults =
            if ((tableResults |> List.length) + (columnResults |> List.length)) < maxResults then
                relations |> List.filterMap (relationMatch query)

            else
                []
    in
    (tableResults ++ columnResults ++ relationResults) |> List.sortBy (\( r, _ ) -> negate r) |> List.take maxResults |> List.map Tuple.second


tableMatch : String -> ErdTable -> Maybe ( Float, SearchResult )
tableMatch query table =
    if table.name == query then
        Just ( 10, FoundTable table )

    else if table.name |> String.startsWith query then
        Just ( 9 + shortBonus table.name, FoundTable table )

    else if table.name |> String.contains query then
        Just ( 8 + shortBonus table.name, FoundTable table )

    else if
        (table.comment |> M.any (.text >> String.contains query))
            || (table.primaryKey |> M.any (.name >> String.contains query))
            || (table.uniques |> List.any (\u -> (u.name |> String.contains query) || (u.definition |> String.contains query)))
            || (table.indexes |> List.any (\i -> (i.name |> String.contains query) || (i.definition |> String.contains query)))
            || (table.checks |> List.any (\c -> (c.name |> String.contains query) || (c.predicate |> String.contains query)))
    then
        Just ( 7 + shortBonus table.name, FoundTable table )

    else
        Nothing


columnMatch : String -> ErdTable -> ErdColumn -> Maybe ( Float, SearchResult )
columnMatch query table column =
    if column.name == query then
        Just ( 1, FoundColumn table column )

    else if column.name |> String.startsWith query then
        Just ( 0.9, FoundColumn table column )

    else if column.name |> String.contains query then
        Just ( 0.8, FoundColumn table column )

    else if
        (column.comment |> M.any (.text >> String.contains query))
            || (column.kind |> String.contains query)
            || (column.default |> M.any (String.contains query))
    then
        Just ( 0.7, FoundColumn table column )

    else
        Nothing


relationMatch : String -> ErdRelation -> Maybe ( Float, SearchResult )
relationMatch query relation =
    if relation.name == query then
        Just ( 0.1, FoundRelation relation )

    else if relation.name |> String.startsWith query then
        Just ( 0.09, FoundRelation relation )

    else if relation.name |> String.contains query then
        Just ( 0.08, FoundRelation relation )

    else if
        (relation.src.column |> String.contains query)
            || (relation.ref.column |> String.contains query)
            || (relation.src.table |> Tuple.second |> String.contains query)
            || (relation.ref.table |> Tuple.second |> String.contains query)
    then
        Just ( 0.07, FoundRelation relation )

    else
        Nothing


shortBonus : String -> Float
shortBonus text =
    1 / toFloat (String.length text)
