module PagesComponents.App.Views.Menu exposing (viewMenu)

import Conf exposing (conf)
import Dict exposing (Dict)
import FontAwesome.Icon exposing (viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, button, div, h5, text)
import Html.Attributes exposing (class, id, style, tabindex, title, type_)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy2)
import Libs.Bool exposing (cond)
import Libs.Bootstrap exposing (BsColor(..), Toggle(..), bsBackdrop, bsButton, bsButtonGroup, bsDismiss, bsScroll, bsToggleCollapse)
import Libs.Html.Attributes exposing (ariaLabel, ariaLabelledBy)
import Libs.List as L
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.String as S exposing (plural)
import Models.Project exposing (Layout, Schema, Table, TableId, showTableId, tableIdAsString)
import PagesComponents.App.Models exposing (Msg(..))


viewMenu : Maybe Schema -> Html Msg
viewMenu schema =
    div [ id conf.ids.menu, class "offcanvas offcanvas-start", bsScroll True, bsBackdrop "false", ariaLabelledBy (conf.ids.menu ++ "-label"), tabindex -1 ]
        [ div [ class "offcanvas-header" ]
            [ h5 [ class "offcanvas-title", id (conf.ids.menu ++ "-label") ] [ text "Menu" ]
            , button [ type_ "button", class "btn-close text-reset", bsDismiss Offcanvas, ariaLabel "Close" ] []
            ]
        , div [ class "offcanvas-body" ]
            ([ div [] [ bsButton Primary [ onClick ChangeProject ] [ text "Switch from project" ] ]
             , div [ style "margin-top" "1em" ] [ bsButton Primary [ onClick (FindPath Nothing Nothing) ] [ text "Find path" ] ]
             ]
                ++ (schema
                        |> Maybe.map
                            (\s ->
                                if Dict.isEmpty s.tables then
                                    []

                                else
                                    [ div [ style "margin-top" "1em" ]
                                        [ bsButtonGroup "Toggle all"
                                            [ bsButton Secondary [ onClick HideAllTables ] [ text "Hide all tables" ]
                                            , bsButton Secondary [ onClick ShowAllTables ] [ text "Show all tables" ]
                                            ]
                                        ]
                                    , div [ style "margin-top" "1em" ]
                                        [ text
                                            ((s.tables |> Dict.size |> String.fromInt)
                                                ++ " tables, "
                                                ++ (s.tables |> Dict.foldl (\_ t c -> c + Ned.size t.columns) 0 |> String.fromInt)
                                                ++ " columns, "
                                                ++ (s.relations |> List.length |> String.fromInt)
                                                ++ " relations"
                                            )
                                        ]
                                    , lazy2 viewTableList s.tables s.layout
                                    ]
                            )
                        |> Maybe.withDefault []
                   )
            )
        ]


viewTableList : Dict TableId Table -> Layout -> Html Msg
viewTableList tables layout =
    div [ style "margin-top" "1em" ]
        [ Keyed.node "div"
            [ class "list-group" ]
            (tables
                |> Dict.values
                |> L.groupBy (\t -> t.id |> Tuple.second |> S.wordSplit |> List.head |> Maybe.withDefault "")
                |> Dict.toList
                |> List.sortBy (\( name, _ ) -> name)
                |> List.concatMap
                    (\( groupTitle, groupedTables ) ->
                        [ ( groupTitle
                          , button ([ class "list-group-item list-group-item-secondary text-start" ] ++ bsToggleCollapse (groupTitle ++ "-table-list"))
                                [ text (groupTitle ++ " (" ++ plural (Nel.length groupedTables) "" "1 table" "tables" ++ ")") ]
                          )
                        , ( groupTitle ++ "-collapse"
                          , Keyed.node "div"
                                [ class "collapse show", id (groupTitle ++ "-table-list") ]
                                (groupedTables
                                    |> Nel.map
                                        (\t ->
                                            ( tableIdAsString t.id
                                            , div [ class "list-group-item d-flex", title (showTableId t.id) ]
                                                [ div [ class "text-truncate me-auto" ] [ text (showTableId t.id) ]
                                                , cond (layout.tables |> L.memberBy .id t.id)
                                                    (button [ type_ "button", class "link text-muted", onClick (HideTable t.id) ] [ viewIcon Icon.eyeSlash ])
                                                    (button [ type_ "button", class "link text-muted", onClick (ShowTable t.id) ] [ viewIcon Icon.eye ])
                                                ]
                                            )
                                        )
                                    |> Nel.toList
                                )
                          )
                        ]
                    )
            )
        ]
