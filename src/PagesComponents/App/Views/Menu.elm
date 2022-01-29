module PagesComponents.App.Views.Menu exposing (viewMenu)

import Conf
import Dict exposing (Dict)
import FontAwesome.Icon exposing (viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, br, button, div, h5, text)
import Html.Attributes exposing (class, id, style, tabindex, title, type_)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy2)
import Libs.Bool exposing (cond)
import Libs.Bootstrap exposing (Toggle(..), bsBackdrop, bsDismiss, bsScroll, bsToggleCollapse)
import Libs.Html.Attributes exposing (ariaLabel, ariaLabelledby)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId as HtmlId
import Libs.Ned as Ned
import Libs.String as S
import Models.Project exposing (Project)
import Models.Project.Layout exposing (Layout)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.App.Models exposing (Msg(..))


viewMenu : Maybe Project -> Html Msg
viewMenu project =
    div [ id Conf.ids.menu, class "offcanvas offcanvas-start", bsScroll True, bsBackdrop "false", ariaLabelledby (Conf.ids.menu ++ "-label"), tabindex -1 ]
        [ div [ class "offcanvas-header" ]
            [ h5 [ class "offcanvas-title", id (Conf.ids.menu ++ "-label") ] [ text (project |> M.mapOrElse (\_ -> "Table list") "Menu") ]
            , button [ type_ "button", class "btn-close text-reset", bsDismiss Offcanvas, ariaLabel "Close" ] []
            ]
        , div [ class "offcanvas-body" ]
            (project
                |> M.mapOrElse
                    (\p ->
                        [ div []
                            [ text
                                ((p.tables |> Dict.size |> String.fromInt)
                                    ++ " tables, "
                                    ++ (p.tables |> Dict.foldl (\_ t c -> c + Ned.size t.columns) 0 |> String.fromInt)
                                    ++ " columns, "
                                    ++ (p.relations |> List.length |> String.fromInt)
                                    ++ " relations"
                                )
                            ]
                        , lazy2 viewTableList p.tables p.layout
                        ]
                    )
                    [ text "You should load a project!"
                    , br [] []
                    , button [ type_ "button", class "btn btn-primary my-3", onClick ChangeProject ] [ text "Load a project" ]
                    ]
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
                          , button ([ class "list-group-item list-group-item-secondary text-start" ] ++ bsToggleCollapse ((groupTitle ++ "-table-list") |> HtmlId.from))
                                [ text (groupTitle ++ " (" ++ (groupedTables |> S.pluralizeL "table") ++ ")") ]
                          )
                        , ( groupTitle ++ "-collapse"
                          , Keyed.node "div"
                                [ class "collapse show", id ((groupTitle ++ "-table-list") |> HtmlId.from) ]
                                (groupedTables
                                    |> List.map
                                        (\t ->
                                            ( TableId.toString t.id
                                            , div [ class "list-group-item d-flex", title (TableId.show t.id) ]
                                                [ div [ class "text-truncate me-auto" ] [ text (TableId.show t.id) ]
                                                , cond (layout.tables |> L.memberBy .id t.id)
                                                    (button [ type_ "button", class "link text-muted", onClick (HideTable t.id) ] [ viewIcon Icon.eyeSlash ])
                                                    (button [ type_ "button", class "link text-muted", onClick (ShowTable t.id) ] [ viewIcon Icon.eye ])
                                                ]
                                            )
                                        )
                                )
                          )
                        ]
                    )
            )
        ]
