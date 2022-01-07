module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Divider as Divider
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
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.Theme exposing (Theme)
import Models.Project exposing (Project)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))
import Services.SourceParsing.Views
import Shared
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewNewProject : Shared.Model -> Model -> List (Html Msg)
viewNewProject shared model =
    appShell shared.theme
        (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline ArrowLeft [ Tw.inline_block ], text " ", text model.selectedMenu ] ]
        [ viewContent shared.theme
            model
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


viewContent : Theme -> Model -> PageModel -> Html Msg
viewContent theme model page =
    div [ css [ Tw.divide_y, Bp.lg [ Tw.grid, Tw.grid_cols_12, Tw.divide_x ] ] ]
        [ aside [ css [ Tw.py_6, Bp.lg [ Tw.col_span_3 ] ] ]
            [ nav [ css [ Tw.space_y_1 ] ] (page.tabs |> List.map (viewTab theme model.selectedTab)) ]
        , div [ css [ Tw.px_4, Tw.py_6, Bp.sm [ Tw.p_6 ], Bp.lg [ Tw.pb_8, Tw.col_span_9, Tw.rounded_r_lg ] ] ]
            [ viewTabContent theme model ]
        ]


viewTab : Theme -> Tab -> TabModel Tab -> Html Msg
viewTab theme selected tab =
    if tab.tab == selected then
        a [ href "", css [ Color.bg theme.color 50, Color.border theme.color 500, Color.text theme.color 700, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ Color.bg theme.color 50, Color.text theme.color 700 ] ], ariaCurrent "page" ]
            [ Icon.outline tab.icon [ Color.text theme.color 500, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]

    else
        a [ href "", onClick (SelectTab tab.tab), css [ Tw.border_transparent, Tw.text_gray_900, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ Tw.bg_gray_50, Tw.text_gray_900 ] ] ]
            [ Icon.outline tab.icon [ Tw.text_gray_400, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]


viewTabContent : Theme -> Model -> Html Msg
viewTabContent theme model =
    div []
        [ case model.selectedTab of
            Schema ->
                viewSchemaUpload theme

            Sample ->
                viewSampleSelection theme model.selectedSample
        , viewSchemaImport theme model
        ]


viewSchemaUpload : Theme -> Html Msg
viewSchemaUpload theme =
    div []
        [ viewHeading "Import your SQL schema" "Everything stay on your machine, don't worry about your schema privacy."
        , form []
            [ div [ css [ Tw.mt_6, Tw.grid, Tw.grid_cols_1, Tw.gap_y_6, Tw.gap_x_4, Bp.sm [ Tw.grid_cols_6 ] ] ]
                [ div [ css [ Bp.sm [ Tw.col_span_6 ] ] ]
                    [ FileInput.basic theme "file-upload" SelectLocalFile
                    ]
                ]
            ]
        ]


viewSampleSelection : Theme -> Maybe String -> Html Msg
viewSampleSelection theme selectedSample =
    div []
        [ viewHeading "Explore a sample schema" "If you want to see what Azimutt is capable of, you can pick a schema a play with it."
        , ItemList.withIcons theme
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
                        , onClick = SelectSample s.key
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


viewSchemaImport : Theme -> Model -> Html Msg
viewSchemaImport theme model =
    div []
        ((((model.selectedLocalFile |> Maybe.map (\f -> f.name ++ " file")) |> M.orElse (model.selectedSample |> Maybe.map (\s -> s ++ " sample")))
            |> Maybe.map2
                (\p source ->
                    [ div [ css [ Tw.mt_6 ] ] [ Divider.withLabel (model.project |> M.mapOrElse (\_ -> "Parsed!") "Parsing ...") ]
                    , Services.SourceParsing.Views.viewLogs source p
                    , Services.SourceParsing.Views.viewErrorAlert p
                    ]
                )
                model.parsedSchema
            |> Maybe.withDefault []
         )
            ++ (model.project |> M.mapOrElse (\p -> [ viewActions theme p ]) [])
        )


viewActions : Theme -> Project -> Html Msg
viewActions theme project =
    div [ css [ Tw.mt_6 ] ]
        [ div [ css [ Tw.flex, Tw.justify_end ] ]
            [ Button.white3 theme.color [ onClick DropSchema ] [ text "Trash this" ]
            , Button.primary3 theme.color [ onClick (CreateProject project), css [ Tw.ml_3 ] ] [ text "Create project!" ]
            ]
        ]
