module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css exposing (Style, focus, hover)
import Css.Global as Global
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, br, button, div, h1, h3, header, img, input, label, li, main_, nav, p, span, text, ul)
import Html.Styled.Attributes exposing (alt, css, for, height, href, id, name, placeholder, src, tabindex, title, type_, width)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.DateTime exposing (formatDate)
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaCurrent, ariaExpanded, ariaHaspopup, ariaHidden, role)
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.String as S
import Libs.Tailwind.Utilities exposing (focusWithin)
import Models.Project exposing (Project)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Shared exposing (StoredProjects(..))
import Tailwind.Breakpoints exposing (lg, md, sm)
import Tailwind.Utilities exposing (absolute, bg_gray_100, bg_gray_50, bg_indigo_500, bg_indigo_600, bg_indigo_700, bg_opacity_75, bg_white, block, border, border_2, border_b, border_dashed, border_gray_200, border_gray_400, border_indigo_300, border_indigo_400, border_indigo_700, border_none, border_opacity_25, border_t, border_transparent, border_white, col_span_1, divide_gray_200, divide_x, divide_y, flex, flex_1, flex_col, flex_grow, flex_grow_0, flex_shrink_0, flow_root, font_bold, font_medium, gap_6, globalStyles, grid, grid_cols_1, grid_cols_2, grid_cols_3, grid_cols_4, h_10, h_12, h_16, h_8, h_full, hidden, inline_flex, inset_0, inset_y_0, items_center, justify_between, justify_center, justify_end, leading_5, left_0, max_w_7xl, max_w_lg, max_w_xs, ml_10, ml_2, ml_3, ml_4, ml_6, ml_auto, mt_1, mt_2, mt_3, mt_6, mx_auto, neg_m_2, neg_mt_32, outline_none, p_1, p_2, p_6, p_8, pb_12, pb_3, pb_32, pb_4, pl_10, pl_3, placeholder_gray_500, pointer_events_none, pr_3, pt_2, pt_4, pt_6, px_0, px_2, px_3, px_4, px_5, px_6, px_8, py_10, py_12, py_2, py_4, relative, ring_2, ring_indigo_500, ring_offset_2, ring_offset_indigo_600, ring_white, rounded_full, rounded_lg, rounded_md, rounded_xl, shadow, shadow_lg, shadow_sm, space_x_4, space_y_1, sr_only, text_3xl, text_base, text_center, text_gray_200, text_gray_400, text_gray_500, text_gray_600, text_gray_700, text_gray_900, text_indigo_200, text_indigo_300, text_indigo_600, text_lg, text_sm, text_white, w_10, w_12, w_16, w_48, w_8, w_full)
import Time


type alias Content =
    { title : String
    , brand : Brand
    , navigation : Navigation
    , search : Search
    , profileDropdown : ProfileDropdown
    , mobileMenu : MobileMenu
    }


type alias Brand =
    { logo : Image, url : String }


type alias Navigation =
    { links : List Link }


type alias Search =
    { id : HtmlId }


type alias ProfileDropdown =
    { id : HtmlId, links : List Link }


type alias MobileMenu =
    { id : HtmlId }


type alias Link =
    { url : String, text : String }


type alias Image =
    { src : String, alt : String }


type alias User =
    { avatar : String
    , firstName : String
    , lastName : String
    , email : String
    }


page : Content
page =
    { title = "Dashboard"
    , brand = { url = Route.toHref Route.Home_, logo = { src = "https://tailwindui.com/img/logos/workflow-mark-indigo-300.svg", alt = "Workflow" } }
    , navigation =
        { links =
            [ { url = "#", text = "Dashboard" }
            , { url = "#", text = "Team" }
            , { url = "#", text = "Projects" }
            , { url = "#", text = "Calendar" }
            , { url = "#", text = "Reports" }
            ]
        }
    , search = { id = "search" }
    , profileDropdown =
        { id = "user-menu-button"
        , links =
            [ { url = "#", text = "Your Profile" }
            , { url = "#", text = "Settings" }
            , { url = "#", text = "Sign out" }
            ]
        }
    , mobileMenu = { id = "mobile-menu" }
    }


user : User
user =
    { avatar = "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
    , firstName = "Tom"
    , lastName = "Cook"
    , email = "tom@example.com"
    }


viewProjects : Shared.Model -> Model -> List (Html Msg)
viewProjects shared model =
    [ Global.global globalStyles
    , Global.global [ Global.selector "html" [ h_full, bg_gray_100 ], Global.selector "body" [ h_full ] ]
    , div [ css [ bg_indigo_600, pb_32 ] ]
        [ viewNavigation model
        , viewHeader page.title
        ]
    , div [ css [ neg_mt_32 ] ]
        [ main_ [ css [ max_w_7xl, mx_auto, pb_12, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
            [ div [ css [ bg_white, rounded_lg, shadow, p_8, sm [ p_6 ] ] ] [ viewContent shared ]
            ]
        ]
    ]


viewNavigation : Model -> Html Msg
viewNavigation model =
    nav [ css [ bg_indigo_600, border_b, border_indigo_300, border_opacity_25, lg [ border_none ] ] ]
        [ div [ css [ max_w_7xl, mx_auto, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
            [ div [ css [ relative, h_16, flex, items_center, justify_between, lg [ border_b, border_indigo_400, border_opacity_25 ] ] ]
                [ div [ css [ px_2, flex, items_center, lg [ px_0 ] ] ]
                    [ div [ css [ flex_shrink_0 ] ] [ viewBrand page.brand ]
                    , div [ css [ hidden, lg [ block, ml_10 ] ] ] [ viewNavLinks page.navigation model.activeMenu ]
                    ]
                , viewSearch page.search
                , viewMobileMenuButton page.mobileMenu model.mobileMenuOpen
                , div [ css [ hidden, lg [ block, ml_4 ] ] ]
                    [ div [ css [ flex, items_center ] ]
                        [ viewNotificationsButton
                        , viewProfileDropdown page.profileDropdown model.profileDropdownOpen
                        ]
                    ]
                ]
            ]
        , viewMobileMenu page.navigation page.profileDropdown page.mobileMenu model.activeMenu model.mobileMenuOpen
        ]


viewBrand : Brand -> Html msg
viewBrand brand =
    a [ href brand.url ] [ img [ css [ block, h_8, w_8 ], src brand.logo.src, alt brand.logo.alt, width 32, height 32 ] [] ]


viewNavLinks : Navigation -> Maybe String -> Html Msg
viewNavLinks navigation active =
    div [ css [ flex, space_x_4 ] ] (navigation.links |> List.map (viewLink [ text_sm ] active))


viewMobileNavLinks : Navigation -> Maybe String -> Html Msg
viewMobileNavLinks navigation active =
    div [ css [ px_2, pt_2, pb_3, space_y_1 ] ] (navigation.links |> List.map (viewLink [ block, text_base ] active))


viewLink : List Style -> Maybe String -> Link -> Html Msg
viewLink styles active link =
    if active |> M.contains link.text then
        a [ href link.url, onClick (SelectMenu Nothing), css ([ text_white, rounded_md, py_2, px_3, font_medium, bg_indigo_700 ] ++ styles), ariaCurrent "page" ] [ text link.text ]

    else
        a [ href link.url, onClick (SelectMenu (Just link.text)), css ([ text_white, rounded_md, py_2, px_3, font_medium, hover [ bg_indigo_500, bg_opacity_75 ] ] ++ styles) ] [ text link.text ]


viewSearch : Search -> Html msg
viewSearch search =
    div [ css [ flex_1, px_2, flex, justify_center, lg [ ml_6, justify_end ] ] ]
        [ div [ css [ max_w_lg, w_full, lg [ max_w_xs ] ] ]
            [ label [ for search.id, css [ sr_only ] ] [ text "Search" ]
            , div [ css [ relative, text_gray_400, focusWithin [ text_gray_600 ] ] ]
                [ div [ css [ pointer_events_none, absolute, inset_y_0, left_0, pl_3, flex, items_center ] ] [ Icon.solid Icon.Search [] ]
                , input [ type_ "search", name "search", id search.id, placeholder "Search", css [ block, w_full, bg_white, py_2, pl_10, pr_3, border, border_transparent, rounded_md, leading_5, text_gray_900, placeholder_gray_500, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white, border_white ], sm [ text_sm ] ] ] []
                ]
            ]
        ]


viewNotificationsButton : Html msg
viewNotificationsButton =
    button [ type_ "button", css [ bg_indigo_600, flex_shrink_0, rounded_full, p_1, text_indigo_200, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ], hover [ text_white ] ] ]
        [ span [ css [ sr_only ] ] [ text "View notifications" ]
        , Icon.outline Bell []
        ]


viewProfileDropdown : ProfileDropdown -> Bool -> Html Msg
viewProfileDropdown dropdown isOpen =
    Dropdown.dropdown { id = "profile-dropdown", direction = BottomLeft, isOpen = isOpen }
        (\_ ->
            button [ type_ "button", id dropdown.id, onClick ToggleProfileDropdown, css [ ml_3, bg_indigo_600, rounded_full, flex, text_sm, text_white, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ] ], ariaExpanded isOpen, ariaHaspopup True ]
                [ span [ css [ sr_only ] ] [ text "Open user menu" ]
                , img [ css [ rounded_full, h_8, w_8 ], src user.avatar, alt "Your avatar", width 32, height 32 ] []
                ]
        )
        (\_ ->
            div [ css [ w_48 ] ]
                (dropdown.links |> List.map (\link -> a [ href link.url, role "menuitem", tabindex -1, css [ block, py_2, px_4, text_sm, text_gray_700, hover [ bg_gray_100 ] ] ] [ text link.text ]))
        )


viewMobileMenuButton : MobileMenu -> Bool -> Html Msg
viewMobileMenuButton mobileMenu isOpen =
    div [ css [ flex, lg [ hidden ] ] ]
        [ button [ type_ "button", onClick ToggleMobileMenu, css [ bg_indigo_600, p_2, rounded_md, inline_flex, items_center, justify_center, text_indigo_200, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ], hover [ text_white, bg_indigo_500, bg_opacity_75 ] ], ariaControls mobileMenu.id, ariaExpanded isOpen ]
            [ span [ css [ sr_only ] ] [ text "Open main menu" ]
            , Icon.outline Menu [ B.cond isOpen hidden block ]
            , Icon.outline X [ B.cond isOpen block hidden ]
            ]
        ]


viewMobileMenu : Navigation -> ProfileDropdown -> MobileMenu -> Maybe String -> Bool -> Html Msg
viewMobileMenu navigation profileDropdown mobileMenu activeMenu isOpen =
    let
        open : List Style
        open =
            if isOpen then
                []

            else
                [ hidden ]
    in
    div [ css ([ lg [ hidden ] ] ++ open), id mobileMenu.id ]
        [ viewMobileNavLinks navigation activeMenu
        , div [ css [ pt_4, pb_3, border_t, border_indigo_700 ] ]
            [ div [ css [ px_5, flex, items_center ] ]
                [ div [ css [ flex_shrink_0 ] ]
                    [ img [ css [ rounded_full, h_10, w_10 ], src user.avatar, alt "Your avatar", width 40, height 40 ] []
                    ]
                , div [ css [ ml_3 ] ]
                    [ div [ css [ text_base, font_medium, text_white ] ] [ text (user.firstName ++ " " ++ user.lastName) ]
                    , div [ css [ text_sm, font_medium, text_indigo_300 ] ] [ text user.email ]
                    ]
                , button [ type_ "button", css [ ml_auto, bg_indigo_600, flex_shrink_0, rounded_full, p_1, text_indigo_200, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ], hover [ text_white ] ] ]
                    [ span [ css [ sr_only ] ] [ text "View notifications" ]
                    , Icon.outline Bell []
                    ]
                ]
            , div [ css [ mt_3, px_2, space_y_1 ] ]
                (profileDropdown.links |> List.map (\link -> a [ href link.url, css [ block, rounded_md, py_2, px_3, text_base, font_medium, text_white, hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text link.text ]))
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
