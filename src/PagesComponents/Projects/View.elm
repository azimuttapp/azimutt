module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Css
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, h3, li, p, span, text, ul)
import Html.Styled.Attributes exposing (class, css, href, id, type_)
import Html.Styled.Events exposing (onClick)
import Libs.DateTime exposing (formatDate)
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaHidden, role)
import Libs.Models.Color as Color
import Libs.Models.Theme exposing (Theme)
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Libs.Task as T
import Models.Project exposing (Project)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Shared exposing (StoredProjects(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Time


viewProjects : Shared.Model -> Model -> List (Html Msg)
viewProjects shared model =
    appShell shared.theme
        (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ text model.selectedMenu ]
        [ viewContent shared ]
        [ viewModal model
        ]


viewContent : Shared.Model -> Html Msg
viewContent shared =
    div [ css [ Tw.p_8, Bp.sm [ Tw.p_6 ] ] ]
        [ viewProjectList shared
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


viewNoProjects : Theme -> Html Msg
viewNoProjects theme =
    div []
        [ p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ]
            [ text "You haven’t created any project yet. Import your own schema." ]
        , viewFirstProject theme
        , div [ css [ Tw.mt_6, Tw.text_sm, Tw.font_medium, Color.text theme.color 600 ] ]
            [ text "Or explore a sample one"
            , span [ ariaHidden True ] [ text " →" ]
            ]
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
                        , active = True
                        , onClick = NavigateTo (Route.toHref Route.Projects__New ++ "?sample=" ++ s.key)
                        }
                    )
            )
        ]


viewFirstProject : Theme -> Html msg
viewFirstProject theme =
    a [ href (Route.toHref Route.Projects__New), css [ Tw.mt_6, Tw.relative, Tw.block, Tw.w_full, Tw.border_2, Tw.border_gray_200, Tw.border_dashed, Tw.rounded_lg, Tw.py_12, Tw.text_center, Tw.text_gray_400, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Color.ring theme.color 500 ], Css.hover [ Tw.border_gray_400 ] ] ]
        [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
        , span [ css [ Tw.mt_2, Tw.block, Tw.text_sm, Tw.font_medium ] ] [ text "Create a new project" ]
        ]


viewProjectCard : Time.Zone -> Project -> Html Msg
viewProjectCard zone project =
    li [ css [ Tw.col_span_1, Tw.flex, Tw.flex_col, Tw.border, Tw.border_gray_200, Tw.rounded_lg, Tw.divide_y, Tw.divide_gray_200, Css.hover [ Tw.shadow_lg ] ] ]
        [ div [ css [ Tw.p_6 ] ]
            [ h3 [ css [ Tw.text_lg, Tw.font_medium ] ] [ text project.name ]
            , ul [ css [ Tw.mt_1, Tw.text_gray_500, Tw.text_sm ] ]
                [ li [] [ text ((project.tables |> S.pluralizeD "table") ++ ", " ++ (project.layouts |> S.pluralizeD "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ css [ Tw.flex, Tw.divide_x, Tw.divide_gray_200 ] ]
            [ button [ type_ "button", onClick (confirmDeleteProject project), css [ Tw.flex_grow_0, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Tw.px_4, Css.hover [ Tw.text_gray_500 ] ] ]
                [ Icon.outline Trash [ Tw.text_gray_400 ] ]
                |> Tooltip.t "Delete this project"
            , a [ href (Route.toHref (Route.Projects__Id_ { id = project.id })), css [ Tw.flex_grow, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Css.hover [ Tw.text_gray_500 ] ] ]
                [ Icon.outline ArrowCircleRight [ Tw.text_gray_400 ], span [ css [ Tw.ml_3 ] ] [ text "Open project" ] ]
            ]
        ]


confirmDeleteProject : Project -> Msg
confirmDeleteProject project =
    ConfirmOpen
        { color = Color.red
        , icon = Trash
        , title = "Delete project"
        , message = span [] [ text "Are you sure you want to delete ", bText project.name, text " project?" ]
        , confirm = "Delete " ++ project.name
        , cancel = "Cancel"
        , onConfirm = T.send (DeleteProject project)
        }


viewNewProject : Theme -> Html msg
viewNewProject theme =
    li [ css [ Tw.col_span_1 ] ]
        [ a [ href (Route.toHref Route.Projects__New), css [ Tw.relative, Tw.block, Tw.w_full, Tw.border_2, Tw.border_gray_200, Tw.border_dashed, Tw.rounded_lg, Tw.py_12, Tw.text_center, Tw.text_gray_200, Tu.focusRing ( theme.color, 500 ) ( Color.white, 500 ), Css.hover [ Tw.border_gray_400, Tw.text_gray_400 ] ] ]
            [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
            , span [ css [ Tw.mt_2, Tw.block, Tw.text_sm, Tw.font_medium ] ] [ text "Create a new project" ]
            ]
        ]


viewModal : Model -> Html Msg
viewModal model =
    div [ class "tw-modal", id Conf.ids.modal ]
        [ model.confirm
            |> Maybe.map
                (\c ->
                    Modal.confirm
                        { id = Conf.ids.confirmDialog
                        , icon = c.icon
                        , color = c.color
                        , title = c.title
                        , message = c.message
                        , confirm = c.confirm
                        , cancel = c.cancel
                        , onConfirm = ModalClose (ConfirmAnswer True c.onConfirm)
                        , onCancel = ModalClose (ConfirmAnswer False (T.send Noop))
                        }
                        model.modalOpened
                )
            |> Maybe.withDefault (div [] [])
        ]
