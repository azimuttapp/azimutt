module PagesComponents.Projects.Id_.Views.Navbar.Search exposing (NavbarSearch, viewNavbarSearch)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css
import Dict exposing (Dict)
import Html.Styled exposing (Html, button, div, input, label, span, text)
import Html.Styled.Attributes exposing (autocomplete, css, for, id, name, placeholder, tabindex, type_, value)
import Html.Styled.Events exposing (onBlur, onFocus, onInput, onMouseDown)
import Libs.Html.Styled.Attributes exposing (role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColorLevel(..), TwColorPosition(..))
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.Project exposing (Project)
import Models.Project.Column exposing (Column)
import Models.Project.Layout exposing (Layout)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias NavbarSearch =
    { id : HtmlId
    , search : String
    , project : Project
    }


viewNavbarSearch : Theme -> HtmlId -> NavbarSearch -> Html Msg
viewNavbarSearch theme openedDropdown model =
    div [ css [ Tw.ml_6 ] ]
        [ div [ css [ Tw.max_w_lg, Tw.w_full, Bp.lg [ Tw.max_w_xs ] ] ]
            [ label [ for model.id, css [ Tw.sr_only ] ] [ text "Search" ]
            , Dropdown.dropdown { id = model.id, direction = BottomRight, isOpen = openedDropdown == model.id }
                (\m ->
                    div []
                        [ div [ css [ Tw.pointer_events_none, Tw.absolute, Tw.inset_y_0, Tw.left_0, Tw.pl_3, Tw.flex, Tw.items_center ] ] [ Icon.solid Search [ TwColor.render Text theme.color L200 ] ]
                        , input
                            [ type_ "search"
                            , name "search"
                            , id m.id
                            , placeholder "Search"
                            , autocomplete False
                            , value model.search
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
                                , TwColor.render Bg theme.color L500
                                , TwColor.render Text theme.color L100
                                , TwColor.render Placeholder theme.color L200
                                , Css.focus [ Tw.outline_none, Tw.bg_white, Tw.border_white, Tw.ring_white, TwColor.render Text theme.color L900, TwColor.render Placeholder theme.color L400 ]
                                , Bp.sm [ Tw.text_sm ]
                                ]
                            ]
                            []
                        ]
                )
                (\_ ->
                    if model.search == "" then
                        div []
                            [ span [ role "menuitem", tabindex -1, css [ Tw.text_gray_500, Tw.flex, Tw.w_full, Tw.items_center, Tw.px_4, Tw.py_2, Tw.text_sm ] ]
                                [ text "Type to search into tables (", Icon.solid Icon.Table [], text "), columns (", Icon.solid Tag [], text ") and relations (", Icon.solid ExternalLink [], text ")" ]
                            ]

                    else
                        performSearch model.project.tables model.project.relations model.search
                            |> (\results ->
                                    if results |> List.isEmpty then
                                        div []
                                            [ span [ role "menuitem", tabindex -1, css [ Tw.text_gray_700, Tw.flex, Tw.w_full, Tw.items_center, Tw.px_4, Tw.py_2, Tw.text_sm ] ]
                                                [ text "No result :(" ]
                                            ]

                                    else
                                        div [] (results |> List.map (viewSearchResult model.project.layout))
                               )
                )
            ]
        ]


type SearchResult
    = FoundTable Table
    | FoundColumn Table Column
    | FoundRelation Relation


viewSearchResult : Layout -> SearchResult -> Html Msg
viewSearchResult layout res =
    let
        shownTables : List TableId
        shownTables =
            layout.tables |> List.map .id

        viewItem : msg -> Icon -> List (Html msg) -> Bool -> Html msg
        viewItem =
            \msg icon content disabled ->
                if disabled then
                    span [ role "menuitem", tabindex -1, css [ Tw.text_gray_400, Tw.flex, Tw.w_full, Tw.items_center, Tw.px_4, Tw.py_2, Tw.text_sm ] ]
                        ([ Icon.solid icon [ Tw.mr_3 ] ] ++ content)

                else
                    button [ type_ "button", onMouseDown msg, role "menuitem", tabindex -1, css [ Tw.text_gray_700, Tw.flex, Tw.w_full, Tw.items_center, Tw.px_4, Tw.py_2, Tw.text_sm, Css.hover [ Tw.bg_gray_100, Tw.text_gray_900 ], Css.focus [ Tw.outline_none ] ] ]
                        ([ Icon.solid icon [ Tw.mr_3 ] ] ++ content)
    in
    case res of
        FoundTable table ->
            viewItem (ShowTable table.id) Icon.Table [ text (TableId.show table.id) ] (shownTables |> L.has table.id)

        FoundColumn table column ->
            viewItem (ShowTable table.id) Tag [ span [ css [ Tw.text_gray_500 ] ] [ text (TableId.show table.id ++ ".") ], text column.name ] (shownTables |> L.has table.id)

        FoundRelation relation ->
            if shownTables |> L.hasNot relation.src.table then
                viewItem (ShowTable relation.src.table) ExternalLink [ text relation.name ] False

            else if shownTables |> L.hasNot relation.ref.table then
                viewItem (ShowTable relation.ref.table) ExternalLink [ text relation.name ] False

            else
                viewItem (ShowTable relation.src.table) ExternalLink [ text relation.name ] True


performSearch : Dict TableId Table -> List Relation -> String -> List SearchResult
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
    (tableResults ++ columnResults ++ relationResults) |> List.sortBy (Tuple.first >> negate) |> List.take maxResults |> List.map Tuple.second


tableMatch : String -> Table -> Maybe ( Float, SearchResult )
tableMatch query table =
    if table.name == query then
        Just ( 10, FoundTable table )

    else if table.name |> String.startsWith query then
        Just ( 9 + shortBonus table.name, FoundTable table )

    else if table.name |> String.contains query then
        Just ( 8 + shortBonus table.name, FoundTable table )

    else if
        (table.comment |> M.exist (.text >> String.contains query))
            || (table.primaryKey |> M.exist (.name >> String.contains query))
            || (table.uniques |> List.any (\u -> (u.name |> String.contains query) || (u.definition |> String.contains query)))
            || (table.indexes |> List.any (\i -> (i.name |> String.contains query) || (i.definition |> String.contains query)))
            || (table.checks |> List.any (\c -> (c.name |> String.contains query) || (c.predicate |> String.contains query)))
    then
        Just ( 7 + shortBonus table.name, FoundTable table )

    else
        Nothing


columnMatch : String -> Table -> Column -> Maybe ( Float, SearchResult )
columnMatch query table column =
    if column.name == query then
        Just ( 1, FoundColumn table column )

    else if column.name |> String.startsWith query then
        Just ( 0.9, FoundColumn table column )

    else if column.name |> String.contains query then
        Just ( 0.8, FoundColumn table column )

    else if
        (column.comment |> M.exist (.text >> String.contains query))
            || (column.kind |> String.contains query)
            || (column.default |> M.exist (String.contains query))
    then
        Just ( 0.7, FoundColumn table column )

    else
        Nothing


relationMatch : String -> Relation -> Maybe ( Float, SearchResult )
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
