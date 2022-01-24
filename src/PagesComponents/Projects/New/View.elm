module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.FileInput as FileInput
import Components.Molecules.ItemList as ItemList
import Conf
import Css
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, aside, div, form, h2, nav, p, span, text)
import Html.Styled.Attributes exposing (css, href)
import Html.Styled.Events exposing (onClick)
import Libs.Html.Styled.Attributes exposing (ariaCurrent)
import Libs.Models.Color as Color
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))
import Services.SQLSource as SQLSource exposing (SQLSourceMsg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewNewProject : Model -> List (Html Msg)
viewNewProject model =
    appShell (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline ArrowLeft [ Tw.inline_block ], text " ", text model.selectedMenu ] ]
        [ viewContent model
            { tabs =
                [ { tab = Schema, icon = DocumentText, text = "From SQL schema" }
                , { tab = Sample, icon = Collection, text = "From sample" }
                ]
            }
        ]
        []


type alias PageModel =
    { tabs : List (TabModel Tab)
    }


type alias TabModel tab =
    { tab : tab, icon : Icon, text : String }


viewContent : Model -> PageModel -> Html Msg
viewContent model page =
    div [ css [ Tw.divide_y, Bp.lg [ Tw.grid, Tw.grid_cols_12, Tw.divide_x ] ] ]
        [ aside [ css [ Tw.py_6, Bp.lg [ Tw.col_span_3 ] ] ]
            [ nav [ css [ Tw.space_y_1 ] ] (page.tabs |> List.map (viewTab model.selectedTab)) ]
        , div [ css [ Tw.px_4, Tw.py_6, Bp.sm [ Tw.p_6 ], Bp.lg [ Tw.pb_8, Tw.col_span_9, Tw.rounded_r_lg ] ] ]
            [ viewTabContent model ]
        ]


viewTab : Tab -> TabModel Tab -> Html Msg
viewTab selected tab =
    if tab.tab == selected then
        a [ href "", css [ Color.bg Conf.theme.color 50, Color.border Conf.theme.color 500, Color.text Conf.theme.color 700, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ Color.bg Conf.theme.color 50, Color.text Conf.theme.color 700 ] ], ariaCurrent "page" ]
            [ Icon.outline tab.icon [ Color.text Conf.theme.color 500, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]

    else
        a [ href "", onClick (SelectTab tab.tab), css [ Tw.border_transparent, Tw.text_gray_900, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ Tw.bg_gray_50, Tw.text_gray_900 ] ] ]
            [ Icon.outline tab.icon [ Tw.text_gray_400, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]


viewTabContent : Model -> Html Msg
viewTabContent model =
    div []
        ([ case model.selectedTab of
            Schema ->
                viewSchemaUpload

            Sample ->
                viewSampleSelection model.parsing.selectedSample
         , SQLSource.viewParsing model.parsing
         ]
            ++ (model.parsing.parsedSource |> Maybe.map2 (\( projectId, _, _ ) source -> [ viewActions projectId source ]) model.parsing.loadedFile |> Maybe.withDefault [])
        )


viewSchemaUpload : Html Msg
viewSchemaUpload =
    div []
        [ viewHeading "Import your SQL schema" "Everything stay on your machine, don't worry about your schema privacy."
        , form []
            [ div [ css [ Tw.mt_6, Tw.grid, Tw.grid_cols_1, Tw.gap_y_6, Tw.gap_x_4, Bp.sm [ Tw.grid_cols_6 ] ] ]
                [ div [ css [ Bp.sm [ Tw.col_span_6 ] ] ]
                    [ FileInput.basic Conf.theme "file-upload" (SelectLocalFile >> SQLSourceMsg)
                    ]
                ]
            ]
        ]


viewSampleSelection : Maybe String -> Html Msg
viewSampleSelection selectedSample =
    div []
        [ viewHeading "Explore a sample schema" "If you want to see what Azimutt is capable of, you can pick a schema a play with it."
        , ItemList.withIcons Conf.theme
            (Conf.schemaSamples
                |> Dict.values
                |> List.sortBy .tables
                |> List.map
                    (\s ->
                        { color = s.color
                        , icon = s.icon
                        , title = s.name ++ " (" ++ (s.tables |> String.fromInt) ++ " tables)"
                        , description = s.description
                        , active = selectedSample == Nothing || selectedSample == Just s.key
                        , onClick = SQLSourceMsg (SelectSample s.key)
                        }
                    )
            )
        ]


viewHeading : String -> String -> Html msg
viewHeading title description =
    div []
        [ h2 [ css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ] [ text title ]
        , p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ] [ text description ]
        ]


viewActions : ProjectId -> Source -> Html Msg
viewActions projectId source =
    div [ css [ Tw.mt_6 ] ]
        [ div [ css [ Tw.flex, Tw.justify_end ] ]
            [ Button.white3 Conf.theme.color [ onClick DropSchema ] [ text "Trash this" ]
            , Button.primary3 Conf.theme.color [ onClick (CreateProject projectId source), css [ Tw.ml_3 ] ] [ text "Create project!" ]
            ]
        ]
