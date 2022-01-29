module PagesComponents.Projects.Id_.Views.Navbar.Search exposing (viewNavbarSearch)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Conf
import Css
import Dict exposing (Dict)
import Html.Styled exposing (Attribute, Html, button, div, input, kbd, label, span, text)
import Html.Styled.Attributes exposing (autocomplete, css, for, id, name, placeholder, tabindex, type_, value)
import Html.Styled.Events exposing (onBlur, onFocus, onInput, onMouseDown)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Tailwind.Utilities as Tu
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), SearchModel)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewNavbarSearch : SearchModel -> Dict TableId ErdTable -> List ErdRelation -> List TableId -> HtmlId -> HtmlId -> Html Msg
viewNavbarSearch search tables relations shownTables htmlId openedDropdown =
    div [ css [ Tw.ml_6 ] ]
        [ div [ css [ Tw.max_w_lg, Tw.w_full, Bp.lg [ Tw.max_w_xs ] ] ]
            [ label [ for htmlId, css [ Tw.sr_only ] ] [ text "Search" ]
            , Dropdown.dropdown { id = htmlId, direction = BottomRight, isOpen = openedDropdown == htmlId }
                (\m ->
                    div []
                        [ div [ css [ Tw.pointer_events_none, Tw.absolute, Tw.inset_y_0, Tw.left_0, Tw.pl_3, Tw.flex, Tw.items_center ] ] [ Icon.solid Search [ Color.text Conf.theme.color 200 ] ]
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
                            , css
                                [ Tw.block
                                , Tw.w_full
                                , Tw.pl_10
                                , Tw.pr_3
                                , Tw.py_2
                                , Tw.border
                                , Tw.border_transparent
                                , Tw.rounded_md
                                , Tw.leading_5
                                , Color.bg Conf.theme.color 500
                                , Color.text Conf.theme.color 100
                                , Color.placeholder Conf.theme.color 200
                                , Css.focus [ Tw.outline_none, Tw.bg_white, Tw.border_white, Tw.ring_white, Color.text Conf.theme.color 900, Color.placeholder Conf.theme.color 400 ]
                                , Bp.sm [ Tw.text_sm ]
                                ]
                            ]
                            []
                        , Conf.hotkeys
                            |> Dict.get "search-open"
                            |> Maybe.andThen List.head
                            |> M.mapOrElse
                                (\h ->
                                    div [ css [ Tw.absolute, Tw.inset_y_0, Tw.right_0, Tw.flex, Tw.py_1_dot_5, Tw.pr_1_dot_5 ] ]
                                        [ kbd [ css [ Tw.inline_flex, Tw.items_center, Tw.border, Color.border Conf.theme.color 300, Tw.rounded, Tw.px_2, Tw.text_sm, Tw.font_sans, Tw.font_medium, Color.text Conf.theme.color 300 ] ]
                                            [ text h.key ]
                                        ]
                                )
                                (div [] [])
                        ]
                )
                (\m ->
                    if search.text == "" then
                        div []
                            [ span [ role "menuitem", tabindex -1, css [ Tw.flex, Tw.w_full, Tw.items_center, Dropdown.itemDisabledStyles ] ]
                                [ text "Type to search into tables (", Icon.solid Icon.Table [], text "), columns (", Icon.solid Tag [], text ") and relations (", Icon.solid ExternalLink [], text ")" ]
                            ]

                    else
                        performSearch tables relations search.text
                            |> (\results ->
                                    if results |> List.isEmpty then
                                        div []
                                            [ span [ role "menuitem", tabindex -1, css [ Tw.flex, Tw.w_full, Tw.items_center, Dropdown.itemDisabledStyles ] ]
                                                [ text "No result :(" ]
                                            ]

                                    else
                                        div [ css [ Tu.max_h 600 "px", Tw.overflow_y_auto ] ]
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

                    commonStyles : Css.Style
                    commonStyles =
                        Css.batch [ Tw.flex, Tw.w_full, Tw.items_center ]
                in
                if disabled then
                    span (commonAttrs ++ [ css [ commonStyles, Dropdown.itemDisabledStyles, Tu.when (active == index) [ Color.text Conf.theme.color 400 ] ] ])
                        ([ Icon.solid icon [ Tw.mr_3 ] ] ++ content)

                else
                    button (commonAttrs ++ [ type_ "button", onMouseDown msg, css [ commonStyles, Dropdown.itemStyles, Css.focus [ Tw.outline_none ], Tu.when (active == index) [ Color.bg Conf.theme.color 600, Tw.text_white ] ] ])
                        ([ Icon.solid icon [ Tw.mr_3 ] ] ++ content)
    in
    case res of
        FoundTable table ->
            viewItem (ShowTable table.id) Icon.Table [ text (TableId.show table.id) ] (shownTables |> L.has table.id)

        FoundColumn table column ->
            viewItem (ShowTable table.id) Tag [ span [ css [ Tw.opacity_50 ] ] [ text (TableId.show table.id ++ ".") ], text column.name ] (shownTables |> L.has table.id)

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
