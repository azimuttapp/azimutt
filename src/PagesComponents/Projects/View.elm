module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Organisms.Header as Header
import Conf exposing (theme)
import Css exposing (focus, hover)
import Css.Global as Global
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, br, button, div, h1, h3, header, li, main_, p, span, text, ul)
import Html.Styled.Attributes exposing (css, href, title, type_)
import Html.Styled.Events exposing (onClick)
import Libs.DateTime exposing (formatDate)
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaHidden, role)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.String as S
import Libs.Tailwind.Utilities exposing (focusWithin)
import Models.Project exposing (Project)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Shared exposing (StoredProjects(..))
import Tailwind.Breakpoints exposing (lg, md, sm)
import Tailwind.Utilities exposing (absolute, bg_gray_100, bg_gray_50, bg_indigo_600, bg_indigo_700, bg_white, block, border, border_2, border_dashed, border_gray_200, border_gray_400, col_span_1, divide_gray_200, divide_x, divide_y, flex, flex_col, flex_grow, flex_grow_0, flex_shrink_0, flow_root, font_bold, font_medium, gap_6, globalStyles, grid, grid_cols_1, grid_cols_2, grid_cols_3, grid_cols_4, h_12, h_16, h_full, inline_flex, inset_0, items_center, justify_center, max_w_7xl, ml_2, ml_3, mt_1, mt_2, mt_6, mx_auto, neg_m_2, neg_mt_32, outline_none, p_2, p_6, p_8, pb_12, pb_32, pb_4, pt_6, px_4, px_6, px_8, py_10, py_12, py_2, py_4, relative, ring_2, ring_indigo_500, ring_offset_2, rounded_lg, rounded_md, rounded_xl, shadow, shadow_lg, shadow_sm, space_x_4, text_3xl, text_center, text_gray_200, text_gray_400, text_gray_500, text_gray_700, text_gray_900, text_indigo_600, text_lg, text_sm, text_white, w_12, w_16, w_full)
import Time


viewProjects : Shared.Model -> Model -> List (Html Msg)
viewProjects shared model =
    [ Global.global globalStyles
    , Global.global [ Global.selector "html" [ h_full, bg_gray_100 ], Global.selector "body" [ h_full ] ]
    , div [ css [ TwColor.render Bg theme.color L600, pb_32 ] ]
        [ Header.app
            { theme = theme
            , brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
            , navigation =
                { links = [ { url = "", text = "Dashboard" } ]
                , onClick = \link -> SelectMenu link.text
                }
            , search = Nothing
            , notifications = Nothing
            , profile = Nothing
            , mobileMenu = { id = "mobile-menu", onClick = ToggleMobileMenu }
            }
            { navigationActive = model.navigationActive
            , mobileMenuOpen = model.mobileMenuOpen
            , profileOpen = False
            }
        , viewHeader model.navigationActive
        ]
    , div [ css [ neg_mt_32 ] ]
        [ main_ [ css [ max_w_7xl, mx_auto, pb_12, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
            [ div [ css [ bg_white, rounded_lg, shadow, p_8, sm [ p_6 ] ] ] [ viewContent shared ]
            ]
        ]
    ]


viewHeader : String -> Html msg
viewHeader title =
    header [ css [ py_10 ] ]
        [ div [ css [ max_w_7xl, mx_auto, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
            [ h1 [ css [ text_3xl, font_bold, text_white ] ] [ text title ]
            ]
        ]


viewContent : Shared.Model -> Html Msg
viewContent shared =
    div []
        [ viewProjectList shared
        , h3 [ css [ text_lg, font_medium, pt_6, pb_4 ] ] [ text "Other" ]
        , div []
            [ button [ type_ "button", css [ px_4, py_2, rounded_md, shadow_sm, text_sm, font_medium, text_white, bg_indigo_600, hover [ bg_indigo_700 ], focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ] ] ]
                [ text "Show modal" ]
            , button [ type_ "button", css [ ml_2, px_4, py_2, rounded_md, shadow_sm, text_sm, font_medium, text_white, bg_indigo_600, hover [ bg_indigo_700 ], focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ] ] ]
                [ text "Show toast" ]
            ]
        ]


viewProjectList : Shared.Model -> Html Msg
viewProjectList shared =
    div []
        [ h3 [ css [ text_lg, font_medium ] ] [ text "Projects" ]
        , case shared.projects of
            Loading ->
                div [ css [ mt_6 ] ] [ text "Loading..." ]

            Loaded [] ->
                viewNoProjects

            Loaded projects ->
                ul [ role "list", css [ mt_6, grid, grid_cols_1, gap_6, lg [ grid_cols_4 ], md [ grid_cols_3 ], sm [ grid_cols_2 ] ] ] ((projects |> List.map (viewProjectCard shared.zone)) ++ [ viewNewProject ])
        ]


viewNoProjects : Html msg
viewNoProjects =
    div []
        [ p [ css [ mt_1, text_sm, text_gray_500 ] ]
            [ text "You haven’t created any project yet. Import your own or select a sample one." ]
        , viewFirstProject
        , div [ css [ mt_6, text_sm, font_medium, text_indigo_600 ] ]
            [ text "Or start from an sample project"
            , span [ ariaHidden True ] [ text " →" ]
            ]
        , ul [ role "list", css [ mt_6, grid, grid_cols_1, gap_6, sm [ grid_cols_2 ] ] ]
            [ viewSampleProject "#" Pink ViewList "Basic" [ text "Simple login/role schema.", br [] [], bText "4 tables", text ", the easiest schema, just enough play with the product." ]
            , viewSampleProject "#" Yellow Calendar "Wordpress" [ text "The well known CMS powering most of the web.", br [] [], bText "12 tables", text ", interesting schema, but with no foreign keys!" ]
            , viewSampleProject "#" Green Photograph "Gospeak.io" [ text "A full featured SaaS for meetup organizers.", br [] [], bText "26 tables", text ", a good real world example to explore." ]
            , viewSampleProject "#" Blue ViewBoards "Create a Board" [ text "Track tasks in different stages of your project." ]
            , viewSampleProject "#" Indigo Table "Create a Spreadsheet" [ text "Lots of numbers and things — good for nerds." ]
            , viewSampleProject "#" Purple Clock "Create a Timeline" [ text "Get a birds-eye-view of your procrastination." ]
            ]
        ]


viewFirstProject : Html msg
viewFirstProject =
    a [ href (Route.toHref Route.Projects__New), css [ mt_6, relative, block, w_full, border_2, border_gray_200, border_dashed, rounded_lg, py_12, text_center, text_gray_400, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ border_gray_400 ] ] ]
        [ Icon.outline DocumentAdd [ mx_auto, h_12, w_12 ]
        , span [ css [ mt_2, block, text_sm, font_medium ] ] [ text "Create a new project" ]
        ]


viewSampleProject : String -> TwColor -> Icon -> String -> List (Html msg) -> Html msg
viewSampleProject url color icon title description =
    li [ css [ flow_root ] ]
        [ div [ css [ relative, neg_m_2, p_2, flex, items_center, space_x_4, rounded_xl, focusWithin [ ring_2, ring_indigo_500 ], hover [ bg_gray_50 ] ] ]
            [ div [ css [ flex_shrink_0, flex, items_center, justify_center, h_16, w_16, rounded_lg, TwColor.render Bg color L500 ] ] [ Icon.outline icon [ text_white ] ]
            , div []
                [ h3 [ css [ text_sm, font_medium, text_gray_900 ] ]
                    [ a [ href url, css [ focus [ outline_none ] ] ]
                        [ span [ css [ absolute, inset_0 ], ariaHidden True ] []
                        , text title
                        ]
                    ]
                , p [ css [ mt_1, text_sm, text_gray_500 ] ] description
                ]
            ]
        ]


viewProjectCard : Time.Zone -> Project -> Html Msg
viewProjectCard zone project =
    li [ css [ col_span_1, flex, flex_col, border, border_gray_200, rounded_lg, divide_y, divide_gray_200, hover [ shadow_lg ] ] ]
        [ div [ css [ p_6 ] ]
            [ h3 [ css [ text_lg, font_medium ] ] [ text project.name ]
            , ul [ css [ mt_1, text_gray_500, text_sm ] ]
                [ li [] [ text ((project.tables |> Dict.size |> S.pluralize "table") ++ ", " ++ (project.layouts |> Dict.size |> S.pluralize "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ css [ flex, divide_x, divide_gray_200 ] ]
            [ button [ type_ "button", title "Delete this project", onClick (DeleteProject project), css [ flex_grow_0, inline_flex, items_center, justify_center, py_4, text_sm, text_gray_700, font_medium, px_4, hover [ text_gray_500 ] ] ]
                [ Icon.outline Trash [ text_gray_400 ] ]
            , a [ href (Route.toHref (Route.Projects__Id_ { id = project.id })), css [ flex_grow, inline_flex, items_center, justify_center, py_4, text_sm, text_gray_700, font_medium, hover [ text_gray_500 ] ] ]
                [ Icon.outline ArrowCircleRight [ text_gray_400 ], span [ css [ ml_3 ] ] [ text "Open project" ] ]
            ]
        ]


viewNewProject : Html msg
viewNewProject =
    li [ css [ col_span_1 ] ]
        [ a [ href (Route.toHref Route.Projects__New), css [ relative, block, w_full, border_2, border_gray_200, border_dashed, rounded_lg, py_12, text_center, text_gray_200, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ border_gray_400, text_gray_400 ] ] ]
            [ Icon.outline DocumentAdd [ mx_auto, h_12, w_12 ]
            , span [ css [ mt_2, block, text_sm, font_medium ] ] [ text "Create a new project" ]
            ]
        ]
