module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Components.Molecules.Toast as Toast
import Components.Organisms.Header as Header
import Css
import Css.Global as Global
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, br, button, div, h1, h3, header, li, main_, p, span, text, ul)
import Html.Styled.Attributes exposing (css, href, title, type_)
import Html.Styled.Events exposing (onClick)
import Libs.DateTime exposing (formatDate)
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaHidden, role)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.String as S
import Libs.Tailwind.Utilities exposing (focusWithin)
import Libs.Task as T
import Models.Project exposing (Project)
import PagesComponents.Projects.Models exposing (Confirm, Model, Msg(..))
import Shared exposing (StoredProjects(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Time


viewProjects : Shared.Model -> Model -> List (Html Msg)
viewProjects shared model =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100 ], Global.selector "body" [ Tw.h_full ] ]
    , div [ css [ TwColor.render Bg shared.theme.color L600, Tw.pb_32 ] ]
        [ Header.app
            { theme = shared.theme
            , brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
            , navigation =
                { links = [ { url = Route.toHref Route.Projects, text = "Dashboard" } ]
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
        , viewHeader [ text model.navigationActive ]
        ]
    , div [ css [ Tw.neg_mt_32 ] ]
        [ main_ [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.pb_12, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ div [ css [ Tw.bg_white, Tw.rounded_lg, Tw.shadow, Tw.p_8, Bp.sm [ Tw.p_6 ] ] ] [ viewContent shared model ]
            ]
        ]
    , viewConfirm shared.theme model.confirm
    , Toast.container (model.toasts |> List.map (\t -> Toast.render shared.theme (ToastHide t.key) t))
    ]


viewHeader : List (Html msg) -> Html msg
viewHeader content =
    header [ css [ Tw.py_10 ] ]
        [ div [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ h1 [ css [ Tw.text_3xl, Tw.font_bold, Tw.text_white ] ] content
            ]
        ]


viewContent : Shared.Model -> Model -> Html Msg
viewContent shared model =
    div []
        [ viewProjectList shared
        , viewOther shared.theme model
        ]


viewProjectList : Shared.Model -> Html Msg
viewProjectList shared =
    div []
        [ h3 [ css [ Tw.text_lg, Tw.font_medium ] ] [ text "Projects" ]
        , case shared.projects of
            Loading ->
                div [ css [ Tw.mt_6 ] ] [ text "Loading..." ]

            Loaded [] ->
                viewNoProjects shared.theme

            Loaded projects ->
                ul [ role "list", css [ Tw.mt_6, Tw.grid, Tw.grid_cols_1, Tw.gap_6, Bp.lg [ Tw.grid_cols_4 ], Bp.md [ Tw.grid_cols_3 ], Bp.sm [ Tw.grid_cols_2 ] ] ] ((projects |> List.map (viewProjectCard shared.zone)) ++ [ viewNewProject shared.theme ])
        ]


viewNoProjects : Theme -> Html msg
viewNoProjects theme =
    div []
        [ p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ]
            [ text "You haven’t created any project yet. Import your own or select a sample one." ]
        , viewFirstProject theme
        , div [ css [ Tw.mt_6, Tw.text_sm, Tw.font_medium, TwColor.render Text theme.color L600 ] ]
            [ text "Or start from an sample project"
            , span [ ariaHidden True ] [ text " →" ]
            ]
        , ul [ role "list", css [ Tw.mt_6, Tw.grid, Tw.grid_cols_1, Tw.gap_6, Bp.sm [ Tw.grid_cols_2 ] ] ]
            [ viewSampleProject theme "#" Pink ViewList "Basic" [ text "Simple login/role schema.", br [] [], bText "4 tables", text ", the easiest schema, just enough play with the product." ]
            , viewSampleProject theme "#" Yellow Calendar "Wordpress" [ text "The well known CMS powering most of the web.", br [] [], bText "12 tables", text ", interesting schema, but with no foreign keys!" ]
            , viewSampleProject theme "#" Green Photograph "Gospeak.io" [ text "A full featured SaaS for meetup organizers.", br [] [], bText "26 tables", text ", a good real world example to explore." ]
            , viewSampleProject theme "#" Blue ViewBoards "Create a Board" [ text "Track tasks in different stages of your project." ]
            , viewSampleProject theme "#" Indigo Table "Create a Spreadsheet" [ text "Lots of numbers and things — good for nerds." ]
            , viewSampleProject theme "#" Purple Clock "Create a Timeline" [ text "Get a birds-eye-view of your procrastination." ]
            ]
        ]


viewFirstProject : Theme -> Html msg
viewFirstProject theme =
    a [ href (Route.toHref Route.Projects__New), css [ Tw.mt_6, Tw.relative, Tw.block, Tw.w_full, Tw.border_2, Tw.border_gray_200, Tw.border_dashed, Tw.rounded_lg, Tw.py_12, Tw.text_center, Tw.text_gray_400, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render Ring theme.color L500 ], Css.hover [ Tw.border_gray_400 ] ] ]
        [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
        , span [ css [ Tw.mt_2, Tw.block, Tw.text_sm, Tw.font_medium ] ] [ text "Create a new project" ]
        ]


viewSampleProject : Theme -> String -> TwColor -> Icon -> String -> List (Html msg) -> Html msg
viewSampleProject theme url color icon title description =
    li [ css [ Tw.flow_root ] ]
        [ div [ css [ Tw.relative, Tw.neg_m_2, Tw.p_2, Tw.flex, Tw.items_center, Tw.space_x_4, Tw.rounded_xl, focusWithin [ Tw.ring_2, TwColor.render Ring theme.color L500 ], Css.hover [ Tw.bg_gray_50 ] ] ]
            [ div [ css [ Tw.flex_shrink_0, Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_16, Tw.w_16, Tw.rounded_lg, TwColor.render Bg color L500 ] ] [ Icon.outline icon [ Tw.text_white ] ]
            , div []
                [ h3 [ css [ Tw.text_sm, Tw.font_medium, Tw.text_gray_900 ] ]
                    [ a [ href url, css [ Css.focus [ Tw.outline_none ] ] ]
                        [ span [ css [ Tw.absolute, Tw.inset_0 ], ariaHidden True ] []
                        , text title
                        ]
                    ]
                , p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ] description
                ]
            ]
        ]


viewProjectCard : Time.Zone -> Project -> Html Msg
viewProjectCard zone project =
    li [ css [ Tw.col_span_1, Tw.flex, Tw.flex_col, Tw.border, Tw.border_gray_200, Tw.rounded_lg, Tw.divide_y, Tw.divide_gray_200, Css.hover [ Tw.shadow_lg ] ] ]
        [ div [ css [ Tw.p_6 ] ]
            [ h3 [ css [ Tw.text_lg, Tw.font_medium ] ] [ text project.name ]
            , ul [ css [ Tw.mt_1, Tw.text_gray_500, Tw.text_sm ] ]
                [ li [] [ text ((project.tables |> Dict.size |> S.pluralize "table") ++ ", " ++ (project.layouts |> Dict.size |> S.pluralize "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ css [ Tw.flex, Tw.divide_x, Tw.divide_gray_200 ] ]
            [ button [ type_ "button", title "Delete this project", onClick (confirmDeleteProject project), css [ Tw.flex_grow_0, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Tw.px_4, Css.hover [ Tw.text_gray_500 ] ] ]
                [ Icon.outline Trash [ Tw.text_gray_400 ] ]
            , a [ href (Route.toHref (Route.Projects__Id_ { id = project.id })), css [ Tw.flex_grow, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Css.hover [ Tw.text_gray_500 ] ] ]
                [ Icon.outline ArrowCircleRight [ Tw.text_gray_400 ], span [ css [ Tw.ml_3 ] ] [ text "Open project" ] ]
            ]
        ]


confirmDeleteProject : Project -> Msg
confirmDeleteProject project =
    ConfirmOpen
        { color = Red
        , icon = Trash
        , title = "Delete project"
        , message = span [] [ text "Are you sure you want to delete ", bText project.name, text " project?" ]
        , confirm = "Delete " ++ project.name
        , cancel = "Cancel"
        , onConfirm = T.send (DeleteProject project)
        , isOpen = True
        }


viewNewProject : Theme -> Html msg
viewNewProject theme =
    li [ css [ Tw.col_span_1 ] ]
        [ a [ href (Route.toHref Route.Projects__New), css [ Tw.relative, Tw.block, Tw.w_full, Tw.border_2, Tw.border_gray_200, Tw.border_dashed, Tw.rounded_lg, Tw.py_12, Tw.text_center, Tw.text_gray_200, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render Ring theme.color L500 ], Css.hover [ Tw.border_gray_400, Tw.text_gray_400 ] ] ]
            [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
            , span [ css [ Tw.mt_2, Tw.block, Tw.text_sm, Tw.font_medium ] ] [ text "Create a new project" ]
            ]
        ]


viewConfirm : Theme -> Confirm -> Html Msg
viewConfirm theme c =
    Modal.confirm theme
        { id = "confirm-modal"
        , icon = c.icon
        , color = c.color
        , title = c.title
        , message = c.message
        , confirm = c.confirm
        , cancel = c.cancel
        , onConfirm = ConfirmAnswer True c.onConfirm
        , onCancel = ConfirmAnswer False (T.send Noop)
        }
        c.isOpen


viewOther : Theme -> Model -> Html Msg
viewOther theme model =
    div []
        [ h3 [ css [ Tw.text_lg, Tw.font_medium, Tw.pt_6, Tw.pb_4 ] ] [ text "Other" ]
        , div []
            [ Button.primary3 theme.color
                [ onClick
                    (ConfirmOpen
                        { color = Green
                        , icon = Check
                        , title = "A modal"
                        , message = span [] [ text "You can open a confirm modal with ConfirmOpen \\o/" ]
                        , confirm = "Great!"
                        , cancel = "Cancel"
                        , onConfirm = T.send Noop
                        , isOpen = True
                        }
                    )
                ]
                [ text "Show modal" ]
            , Button.primary3 theme.color
                [ onClick
                    (ToastAdd (Just 5000)
                        (Toast.Simple
                            { color = Green
                            , icon = Check
                            , title = "Well done! (" ++ (model.toastCpt |> String.fromInt) ++ ")"
                            , message = "Well done :D"
                            }
                        )
                    )
                , css [ Tw.ml_2 ]
                ]
                [ text "Show toast" ]
            ]
        ]
