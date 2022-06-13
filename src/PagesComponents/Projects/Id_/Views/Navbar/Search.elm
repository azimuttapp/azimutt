module PagesComponents.Projects.Id_.Views.Navbar.Search exposing (viewNavbarSearch)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict exposing (Dict)
import Html exposing (Attribute, Html, button, div, input, kbd, label, span, text)
import Html.Attributes exposing (autocomplete, class, for, id, name, placeholder, tabindex, type_, value)
import Html.Events exposing (onBlur, onFocus, onInput, onMouseDown)
import Libs.Bool as B
import Libs.Html.Attributes exposing (css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass, focus, lg, sm)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), SearchModel, confirm)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.Notes as Notes exposing (Notes, NotesKey)
import Simple.Fuzzy


viewNavbarSearch : SearchModel -> Dict TableId ErdTable -> List ErdRelation -> Dict NotesKey Notes -> List TableId -> HtmlId -> HtmlId -> Html Msg
viewNavbarSearch search tables relations notes shownTables htmlId openedDropdown =
    div [ class "ml-6 print:hidden" ]
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
                            , onFocus (DropdownOpen m.id)
                            , onBlur DropdownClose
                            , css [ "block w-full pl-10 pr-3 py-2 border border-transparent rounded-md leading-5 bg-primary-500 text-primary-100 placeholder-primary-200", focus [ "outline-none bg-white border-white ring-white text-primary-900 placeholder-primary-400" ], sm [ "text-sm" ] ]
                            ]
                            []
                        , Conf.hotkeys
                            |> Dict.get "search-open"
                            |> Maybe.andThen List.head
                            |> Maybe.mapOrElse
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
                            [ span [ role "menuitem", tabindex -1, css [ "flex w-full items-center", ContextMenu.itemDisabledStyles ] ]
                                [ text "Type to search into tables (", Icon.solid Icon.Table "", text "), columns (", Icon.solid Tag "", text ") and relations (", Icon.solid ExternalLink "", text ")" ]
                            , button
                                [ type_ "button"
                                , onMouseDown (B.cond (Dict.size tables < 30) ShowAllTables (confirm "Show all tables" (text "You are about to add a lot of tables, it may show down your computer. Continue?") ShowAllTables))
                                , role "menuitem"
                                , tabindex -1
                                , css [ "flex w-full items-center", focus [ "outline-none" ], ContextMenu.itemStyles ]
                                ]
                                [ text ("Show all tables (" ++ (tables |> Dict.size |> String.fromInt) ++ ")") ]
                            ]

                    else
                        performSearch tables relations notes (String.toLower search.text)
                            |> (\results ->
                                    if results |> List.isEmpty then
                                        div []
                                            [ span [ role "menuitem", tabindex -1, css [ "flex w-full items-center", ContextMenu.itemDisabledStyles ] ]
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
                        [ role "menuitem", tabindex -1 ] ++ B.cond (active == index) [ id (searchId ++ "-active-item") ] []

                    commonStyles : TwClass
                    commonStyles =
                        "flex w-full items-center"
                in
                if disabled then
                    span (commonAttrs ++ [ css [ commonStyles, B.cond (active == index) ContextMenu.itemDisabledActiveStyles ContextMenu.itemDisabledStyles ] ])
                        ([ Icon.solid icon "mr-3" ] ++ content)

                else
                    button (commonAttrs ++ [ type_ "button", onMouseDown msg, css [ commonStyles, focus [ "outline-none" ], B.cond (active == index) ContextMenu.itemActiveStyles ContextMenu.itemStyles ] ])
                        ([ Icon.solid icon "mr-3" ] ++ content)
    in
    case res of
        FoundTable table ->
            viewItem (ShowTable table.id Nothing) Icon.Table [ text (TableId.show table.id) ] (shownTables |> List.has table.id)

        FoundColumn table column ->
            viewItem (ShowTable table.id Nothing) Tag [ span [ class "opacity-50" ] [ text (TableId.show table.id ++ ".") ], text column.name ] (shownTables |> List.has table.id)

        FoundRelation relation ->
            if shownTables |> List.hasNot relation.src.table then
                viewItem (ShowTable relation.src.table Nothing) ExternalLink [ text relation.name ] False

            else if shownTables |> List.hasNot relation.ref.table then
                viewItem (ShowTable relation.ref.table Nothing) ExternalLink [ text relation.name ] False

            else
                viewItem (ShowTable relation.src.table Nothing) ExternalLink [ text relation.name ] True


performSearch : Dict TableId ErdTable -> List ErdRelation -> Dict NotesKey Notes -> String -> List SearchResult
performSearch tables relations notes lQuery =
    let
        maxResults : Int
        maxResults =
            30

        tableResults : List ( Float, SearchResult )
        tableResults =
            tables |> Dict.values |> List.filterMap (tableMatch lQuery notes)

        columnResults : List ( Float, SearchResult )
        columnResults =
            if (tableResults |> List.length) < maxResults then
                tables |> Dict.values |> List.concatMap (\table -> table.columns |> Dict.values |> List.filterMap (columnMatch lQuery notes table))

            else
                []

        relationResults : List ( Float, SearchResult )
        relationResults =
            if ((tableResults |> List.length) + (columnResults |> List.length)) < maxResults then
                relations |> List.filterMap (relationMatch lQuery)

            else
                []
    in
    (tableResults ++ columnResults ++ relationResults) |> List.sortBy (\( r, _ ) -> negate r) |> List.take maxResults |> List.map Tuple.second


tableMatch : String -> Dict NotesKey Notes -> ErdTable -> Maybe ( Float, SearchResult )
tableMatch lQuery notes table =
    if String.toLower table.name == lQuery then
        Just ( 9, FoundTable table )

    else if table.name |> String.toLower |> String.startsWith lQuery then
        Just ( 8 + shortBonus table.name, FoundTable table )

    else if table.name |> match lQuery then
        Just ( 7 + shortBonus table.name, FoundTable table )

    else if table.name |> fuzzy lQuery then
        Just ( 6 + shortBonus table.name, FoundTable table )

    else if
        (table.comment |> Maybe.any (.text >> match lQuery))
            || (notes |> Dict.get (Notes.tableKey table.id) |> Maybe.any (match lQuery))
            || (table.primaryKey |> Maybe.andThen .name |> Maybe.any (match lQuery))
            || (table.uniques |> List.any (\u -> (u.name |> match lQuery) || (u.definition |> Maybe.any (match lQuery))))
            || (table.indexes |> List.any (\i -> (i.name |> match lQuery) || (i.definition |> Maybe.any (match lQuery))))
            || (table.checks |> List.any (\c -> (c.name |> match lQuery) || (c.predicate |> Maybe.any (match lQuery))))
    then
        Just ( 5 + shortBonus table.name, FoundTable table )

    else if
        (table.comment |> Maybe.any (.text >> fuzzy lQuery))
            || (notes |> Dict.get (Notes.tableKey table.id) |> Maybe.any (fuzzy lQuery))
    then
        Just ( 4 + shortBonus table.name, FoundTable table )

    else
        Nothing


columnMatch : String -> Dict NotesKey Notes -> ErdTable -> ErdColumn -> Maybe ( Float, SearchResult )
columnMatch lQuery notes table column =
    if String.toLower column.name == lQuery then
        Just ( 0.9, FoundColumn table column )

    else if column.name |> String.toLower |> String.startsWith lQuery then
        Just ( 0.8, FoundColumn table column )

    else if column.name |> match lQuery then
        Just ( 0.7, FoundColumn table column )

    else if column.name |> fuzzy lQuery then
        Just ( 0.6, FoundColumn table column )

    else if
        (column.comment |> Maybe.any (.text >> match lQuery))
            || (notes |> Dict.get (Notes.columnKey { table = table.id, column = column.name }) |> Maybe.any (match lQuery))
            || (column.kind |> match lQuery)
            || (column.default |> Maybe.any (match lQuery))
    then
        Just ( 0.5, FoundColumn table column )

    else if
        (column.comment |> Maybe.any (.text >> fuzzy lQuery))
            || (notes |> Dict.get (Notes.columnKey { table = table.id, column = column.name }) |> Maybe.any (fuzzy lQuery))
    then
        Just ( 0.4, FoundColumn table column )

    else
        Nothing


relationMatch : String -> ErdRelation -> Maybe ( Float, SearchResult )
relationMatch lQuery relation =
    if String.toLower relation.name == lQuery then
        Just ( 0.09, FoundRelation relation )

    else if relation.name |> String.toLower |> String.startsWith lQuery then
        Just ( 0.08, FoundRelation relation )

    else if relation.name |> match lQuery then
        Just ( 0.07, FoundRelation relation )

    else if relation.name |> fuzzy lQuery then
        Just ( 0.06, FoundRelation relation )

    else if
        (relation.src.column |> match lQuery)
            || (relation.ref.column |> match lQuery)
            || (relation.src.table |> Tuple.second |> match lQuery)
            || (relation.ref.table |> Tuple.second |> match lQuery)
    then
        Just ( 0.05, FoundRelation relation )

    else
        Nothing


match : String -> String -> Bool
match lQuery text =
    text |> String.toLower |> String.contains lQuery


fuzzy : String -> String -> Bool
fuzzy lQuery text =
    text |> Simple.Fuzzy.match lQuery


shortBonus : String -> Float
shortBonus text =
    1 / toFloat (String.length text)
